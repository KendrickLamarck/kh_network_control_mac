//
//  KHAccess.swift
//  KH Volume slider
//
//  Created by Leander Blume on 16.01.25.
//

import SwiftUI

@Observable
class KHAccess {
    /*
     Fetches, sends and stores data from speakers.
     */
    
    // ######################## CHANGE THIS TO YOUR PYTHON ############################
    var pythonExecutable = "python3"
    var networkInterface = "en0"
    // ################################################################################

    private var khtoolPath = Bundle.main.url(
        forResource: "khtool", withExtension: "py"
    )!
    private var pythonPath = Bundle.main.url(
        forResource: "python-packages", withExtension: nil
    )

    /// I was wondering whether we should just store a KHJSON instance instead of these values because the whole
    /// thing seems a bit doubled up. But maybe this is good as an abstraction layer between the json and the GUI.
    var volume = 54.0
    var eqs = [Eq(numBands: 10), Eq(numBands: 20)]
    var muted = false
    
    var status: Status = .clean
    
    enum Status {
        case clean
        case fetching
        case sendingEqSettings
        case checkingSpeakerAvailability
        case speakersUnavailable
    }

    enum KHAccessError: Error {
        case processError
        case speakersNotReachable
        case fileError
        case jsonError
    }

    func _runKHToolProcess(args: [String]) async throws {
        let process = Process()
        process.executableURL = URL(filePath: "/bin/sh")
        process.currentDirectoryURL = Bundle.main.resourceURL!
        process.environment = ["PYTHONPATH": pythonPath!.path]
        var argString = ""
        for arg in args {
            argString += " " + arg
        }
        process.arguments = [
            "-c",
            "\(pythonExecutable) \"\(khtoolPath.path)\" -i \(networkInterface)"
                + argString
        ]
        try process.run()
        process.waitUntilExit()
        if process.terminationStatus != 0 {
            throw KHAccessError.processError
        }
    }

    func checkSpeakersAvailable() async throws {
        status = .checkingSpeakerAvailability
        do {
            try await _runKHToolProcess(args: ["--expert", "'{\"osc\":{\"ping\":0}}'"])
            status = .clean
        } catch {
            status = .speakersUnavailable
            throw KHAccessError.speakersNotReachable
        }
    }

    func runKHToolProcess(args: [String]) async throws {
        if status == .speakersUnavailable {
            throw KHAccessError.speakersNotReachable
        }
        return try await _runKHToolProcess(args: args)
    }

    func backupDevice() async throws {
        let backupPath = Bundle.main.path(forResource: "gui_backup", ofType: "json")!
        try await runKHToolProcess(args: ["--backup", "\"" + backupPath + "\""])
    }

    func readBackupAsStruct() throws -> KHJSON {
        let backupURL = Bundle.main.url(
            forResource: "gui_backup", withExtension: "json"
        )!
        let data = try Data(contentsOf: backupURL)
        return try JSONDecoder().decode(KHJSON.self, from: data)
    }
    
    func readStateFromBackup() throws {
        let json = try readBackupAsStruct()
        guard let commands = json.devices.values.first?.commands else {
            throw KHAccessError.jsonError
        }
        muted = commands.audio.out.mute
        volume = commands.audio.out.level
        eqs[0] = commands.audio.out.eq2
        eqs[1] = commands.audio.out.eq3
    }

    func backupAndFetch() async throws {
        status = .fetching
        try await backupDevice()
        try readStateFromBackup()
        status = .clean
    }

    func updateKhjsonWithEq(_ data: KHJSON) throws -> KHJSON {
        var new_data = data
        guard let out = new_data.devices.values.first?.commands.audio.out else {
            throw KHAccessError.jsonError
        }
        var new_data_eqs = [out.eq2, out.eq3]
        for j in 0..<eqs.count {
            new_data_eqs[j] = eqs[j]
        }
        for k in new_data.devices.keys {
            new_data.devices[k]?.commands.audio.out.eq2 = new_data_eqs[0]
            new_data.devices[k]?.commands.audio.out.eq3 = new_data_eqs[1]
        }
        return new_data
    }

    func sendVolumeToDevice() async throws {
        try await runKHToolProcess(args: ["--level", "\(Int(volume))"])
    }

    func sendEqToDevice() async throws {
        status = .sendingEqSettings
        let data = try readBackupAsStruct()
        let updatedData = try updateKhjsonWithEq(data)
        /// set volume to nil manually. This lets us skip creating a backup, speeding up this
        /// operation considerably.
        /// Why do we even do this. We assume the state of the app matches the speaker
        /// state anyway, right?
        //for k in updatedData.devices.keys {
        //    updatedData.devices[k]?.commands.audio.out.level = nil
        //}
        // We can unfortunately not send this with --expert because the request is too
        // long.
        // TODO we can delete the file after running this function. What's
        let eqBackupURL = Bundle.main.url(
            forResource: "gui_eq_settings", withExtension: "json"
        )!
        try updatedData.writeToFile(filePath: eqBackupURL)
        try await runKHToolProcess(args: ["--restore", "\"" + eqBackupURL.path + "\""])
        status = .clean
    }

    func muteOrUnmute() async throws {
        if muted {
            try await runKHToolProcess(args: ["--mute"])
        } else {
            try await runKHToolProcess(args: ["--unmute"])
        }
    }
}

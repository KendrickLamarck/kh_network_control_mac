//
//  KHAccess.swift
//  KH Volume slider
//
//  Created by Leander Blume on 16.01.25.
//

import SwiftUI

@Observable class KHAccess {
    /*
     Fetches, sends and stores data from speakers.
     */
    /// I was wondering whether we should just store a KHJSON instance instead of these values because the whole
    /// thing seems a bit doubled up. But maybe this is good as an abstraction layer between the json and the GUI.

    // UI state
    var volume = 54.0
    var eqs = [Eq(numBands: 10), Eq(numBands: 20)]
    var muted = false
    var logoBrightness = 100.0

    var status: Status = .clean

    // (last known) device state. We compare UI state against this to selectively send
    // changed values to the device.
    private var volumeDevice = 54.0
    private var eqsDevice = [Eq(numBands: 10), Eq(numBands: 20)]
    private var mutedDevice = false
    private var logoBrightnessDevice = 100.0

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
        case invalidCommand
        case fileError
        case jsonError
    }

    let khtoolPath = Bundle.main.url(forResource: "khtool", withExtension: "py")!
    let pythonPath = Bundle.main.url(
        forResource: "python-packages", withExtension: nil
    )!

    private func runKHToolProcess(args: [String], checkAvailable: Bool = true)
        async throws
    {
        if checkAvailable && status == .speakersUnavailable {
            throw KHAccessError.speakersNotReachable
        }
        let pythonExecutable =
            UserDefaults.standard.string(forKey: "pythonExecutable") ?? "python3"
        let networkInterface =
            UserDefaults.standard.string(forKey: "networkInterface") ?? "en0"
        let process = Process()
        process.executableURL = URL(filePath: "/bin/sh")
        process.currentDirectoryURL = Bundle.main.resourceURL!
        process.environment = ["PYTHONPATH": pythonPath.path]
        var argString = ""
        for arg in args {
            argString += " " + arg
        }
        process.arguments = [
            "-c",
            "\"\(pythonExecutable)\" \"\(khtoolPath.path)\" -i \(networkInterface)"
                + argString,
        ]
        try process.run()
        process.waitUntilExit()
        // TODO check for malformed commands / 404 paths and throw the appropriate
        // error
        if process.terminationStatus != 0 {
            throw KHAccessError.processError
        }
    }

    private func sendSSCCommand(path: [String], value: Any, checkAvailable: Bool = true)
        async throws
    {
        /// sends the command `{"p1":{"p2":{String(value)}}` to the device, if
        /// `path=["p1", "p2"]`.
        var jsonPath = String(describing: value)
        for p in path.reversed() {
            jsonPath = "{\"\(p)\":\(jsonPath)}"
        }
        jsonPath = "'" + jsonPath + "'"
        // print(jsonPath)
        try await runKHToolProcess(
            args: ["--expert", jsonPath], checkAvailable: checkAvailable)
    }

    func checkSpeakersAvailable() async throws {
        status = .checkingSpeakerAvailability
        do {
            try await sendSSCCommand(path: ["osc", "ping"], value: 0)
            status = .clean
        } catch {
            status = .speakersUnavailable
            throw KHAccessError.speakersNotReachable
        }
    }

    private func backupDevice() async throws {
        let backupPath = Bundle.main.path(forResource: "gui_backup", ofType: "json")!
        try await runKHToolProcess(args: ["--backup", "\"" + backupPath + "\""])
    }

    private func readBackupAsStruct() throws -> KHJSON {
        let backupURL = Bundle.main.url(
            forResource: "gui_backup", withExtension: "json"
        )!
        let data = try Data(contentsOf: backupURL)
        return try JSONDecoder().decode(KHJSON.self, from: data)
    }

    private func readStateFromBackup() throws {
        let json = try readBackupAsStruct()
        guard let commands = json.devices.values.first?.commands else {
            throw KHAccessError.jsonError
        }
        mutedDevice = commands.audio.out.mute
        volumeDevice = commands.audio.out.level
        eqsDevice[0] = commands.audio.out.eq2
        eqsDevice[1] = commands.audio.out.eq3
        logoBrightnessDevice = commands.ui.logo.brightness

        muted = mutedDevice
        volume = volumeDevice
        eqs = eqsDevice
        logoBrightness = logoBrightnessDevice
    }

    func backupAndFetch() async throws {
        status = .fetching
        try await backupDevice()
        try readStateFromBackup()
        status = .clean
    }

    private func updateKhjsonWithEq(_ data: KHJSON) throws -> KHJSON {
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

    private func sendVolumeToDevice() async throws {
        try await runKHToolProcess(args: ["--level", "\(Int(volume))"])
    }

    private func sendEqToDevice() async throws {
        status = .sendingEqSettings
        let data = try readBackupAsStruct()
        let updatedData = try updateKhjsonWithEq(data)
        // We can unfortunately not send this with --expert because the request is too
        // long.
        let eqBackupURL = Bundle.main.url(
            forResource: "gui_eq_settings", withExtension: "json"
        )!
        try updatedData.writeToFile(filePath: eqBackupURL)
        try await runKHToolProcess(args: ["--restore", "\"" + eqBackupURL.path + "\""])
        status = .clean
    }

    private func sendEqBoost(eqIdx: Int, eqName: String) async throws {
        try await sendSSCCommand(
            path: ["audio", "out", eqName, "boost"], value: eqs[eqIdx].boost)
    }

    private func sendEqEnabled(eqIdx: Int, eqName: String) async throws {
        try await sendSSCCommand(
            path: ["audio", "out", eqName, "enabled"], value: eqs[eqIdx].enabled)
    }
    
    private func sendEqFrequency(eqIdx: Int, eqName: String) async throws {
        try await sendSSCCommand(
            path: ["audio", "out", eqName, "frequency"], value: eqs[eqIdx].frequency)
    }
    
    private func sendEqGain(eqIdx: Int, eqName: String) async throws {
        try await sendSSCCommand(
            path: ["audio", "out", eqName, "gain"], value: eqs[eqIdx].gain)
    }
    
    private func sendEqQ(eqIdx: Int, eqName: String) async throws {
        try await sendSSCCommand(
            path: ["audio", "out", eqName, "q"], value: eqs[eqIdx].q)
    }

    private func sendEqType(eqIdx: Int, eqName: String) async throws {
        // TODO probably have to do more here
        try await sendSSCCommand(
            path: ["audio", "out", eqName, "type"], value: eqs[eqIdx].type)
    }
    
    private func sendMuteOrUnmute() async throws {
        if muted {
            try await runKHToolProcess(args: ["--mute"])
        } else {
            try await runKHToolProcess(args: ["--unmute"])
        }
    }

    private func sendLogoBrightness() async throws {
        /// We don't want to use the `--brightness` option because it can't take floats (although we don't either)
        /// and it only goes up to 100 even though the real brightness goes up to 125.
        try await sendSSCCommand(
            path: ["ui", "logo", "brightness"], value: logoBrightness)
    }

    func send() async throws {
        if volume != volumeDevice {
            try await sendVolumeToDevice()
            volumeDevice = volume
        }
        if muted != mutedDevice {
            try await sendMuteOrUnmute()
            mutedDevice = muted
        }
        if logoBrightness != logoBrightnessDevice {
            try await sendLogoBrightness()
            logoBrightnessDevice = logoBrightness
        }
        for (eqIdx, eqName) in ["eq2", "eq3"].enumerated() {
            if eqs[eqIdx].boost != eqsDevice[eqIdx].boost {
                try await sendEqBoost(eqIdx: eqIdx, eqName: eqName)
                eqsDevice[eqIdx].boost = eqs[eqIdx].boost
            }
            if eqs[eqIdx].enabled != eqsDevice[eqIdx].enabled {
                try await sendEqEnabled(eqIdx: eqIdx, eqName: eqName)
                eqsDevice[eqIdx].enabled = eqs[eqIdx].enabled
            }
            if eqs[eqIdx].frequency != eqsDevice[eqIdx].frequency {
                try await sendEqFrequency(eqIdx: eqIdx, eqName: eqName)
                eqsDevice[eqIdx].frequency = eqs[eqIdx].frequency
            }
            if eqs[eqIdx].gain != eqsDevice[eqIdx].gain {
                try await sendEqGain(eqIdx: eqIdx, eqName: eqName)
                eqsDevice[eqIdx].gain = eqs[eqIdx].gain
            }
            if eqs[eqIdx].q != eqsDevice[eqIdx].q {
                try await sendEqQ(eqIdx: eqIdx, eqName: eqName)
                eqsDevice[eqIdx].q = eqs[eqIdx].q
            }
            if eqs[eqIdx].type != eqsDevice[eqIdx].type {
                try await sendEqType(eqIdx: eqIdx, eqName: eqName)
                eqsDevice[eqIdx].type = eqs[eqIdx].type
            }
        }
        if eqs != eqsDevice {
            try await sendEqToDevice()
            eqsDevice = eqs
        }
    }
}

//
//  KHAccess.swift
//  KH Volume slider
//
//  Created by Leander Blume on 16.01.25.
//

import SwiftUI

@Observable class KHAccess {
    /*
     Fetches, sends and stores data from KH speakers.
     */
    private var scriptPath: URL
    private var pythonPath: URL
    private var khtoolPath: URL
    private var networkInterface: String

    var speakersAvailable: Bool = false
    var volume: Double = 54
    var eqs: [Eq] = [Eq(numBands: 10), Eq(numBands: 20)]

    init() {
        // ####### SET THESE VARIABLES #######################################
        let scriptPath = URL.homeDirectory.appending(path: "code/kh_120")
        let pythonPath = scriptPath.appending(path: ".venv/bin/python")
        let khtoolPath = scriptPath.appending(path: "khtool/khtool.py")
        self.scriptPath = scriptPath
        self.pythonPath = pythonPath
        self.khtoolPath = khtoolPath
        self.networkInterface = "en0"
        // ###################################################################
    }
    
    enum KHAccessError: Error {
        case processError
        case speakersNotReachable
        case fileError
    }
    
    func _runKHToolProcess(args: [String]) async -> Int {
        let process = Process()
        process.executableURL = URL(filePath: "/bin/sh")
        process.currentDirectoryURL = scriptPath
        var argString = ""
        for arg in args {
            argString += " " + arg
        }
        process.arguments = [
          "-c",
          "\(pythonPath.path) \(khtoolPath.path) -i \(networkInterface)" + argString
        ]
        do {
            //print(process.terminationStatus)
            try process.run()
            process.waitUntilExit()
            return Int(process.terminationStatus)
        } catch {
            // TODO print process output with pipe or something
            print("Process failed.")
            return -1
        }
    }

    func checkSpeakersAvailable() async {
        if await _runKHToolProcess(args: ["-q"]) == 0 {
            speakersAvailable = true
        } else {
            speakersAvailable = false
        }
    }

    func runKHToolProcess(args: [String]) async -> Int {
        if await _runKHToolProcess(args: ["-q"]) != 0 {
            return -1
        }
        return await _runKHToolProcess(args: args)
    }

    func backupDevice() async {
        let backupPath = scriptPath.appending(path: "gui_backup.json")
        await _ = runKHToolProcess(args: ["--backup", backupPath.path])
    }

    func readBackupAsStruct() -> KHJSON? {
        let backupPath = scriptPath.appending(path: "gui_backup.json")
        guard let data = try? Data(contentsOf: backupPath) else {
            return nil
        }
        return try? JSONDecoder().decode(KHJSON.self, from: data)
    }

    func readVolumeFromBackup() {
        let json = readBackupAsStruct()
        guard let new_volume = json?.devices.values.first?.commands.audio.out.level else {
            print("fetching volume failed")
            return
        }
        volume = new_volume
    }

    func readEqFromBackup() {
        let json = readBackupAsStruct()
        guard let out = json?.devices.values.first?.commands.audio.out else {
            return
        }
        for (j, eq) in [out.eq2, out.eq3].enumerated() {
            eqs[j] = eq
        }
    }

    func backupAndFetch() async {
        await backupDevice()
        readVolumeFromBackup()
        readEqFromBackup()
    }

    func updateKhjsonWithEq(_ data: KHJSON) -> KHJSON {
        var new_data = data
        guard let out = new_data.devices.values.first?.commands.audio.out else {
            print("updating KHJSON with eq failed")
            return data
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

    func sendVolumeToDevice() async {
        await _ = runKHToolProcess(args: ["--level", "\(Int(volume))"])
    }

    func sendEqToDevice() async {
        guard let data = readBackupAsStruct() else {
            print("Failed to read backup file")
            return
        }
        var updatedData = updateKhjsonWithEq(data)
        // set volume to nil manually. This lets us skip creating a backup, speeding up this
        // operation considerably.
        for k in updatedData.devices.keys {
            updatedData.devices[k]?.commands.audio.out.level = nil
        }
        // We can unfortunately not send this with --expert because the request is too
        // long.
        // TODO we can delete the file after running this function. What's
        let filePath = scriptPath.appending(path: "gui_eq_settings.json")
        do {
            try updatedData.writeToFile(filePath: filePath)
        } catch {
            print("Writing eq settings to file failed")
        }
        await _ = runKHToolProcess(args: ["--restore", filePath.path])
    }
}

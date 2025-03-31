//
//  KHAccessNative.swift
//  KH Volume slider
//
//  Created by Leander Blume on 31.03.25.
//

import SwiftUI

@Observable class KHAccessNative {
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
    
    var device: SSCDevice
    
    init(device device_: SSCDevice) {
        device = device_
    }

    enum Status {
        case clean
        case fetching
        case checkingSpeakerAvailability
        case speakersUnavailable
        case scanning
        case noSpeakersFoundDuringScan
    }

    enum KHAccessError: Error {
        case processError
        case speakersNotReachable
        case fileError
        case jsonError
        case messageNotUnderstood
        case addressNotFound
    }
    
    private func runKHToolProcess(args: [String], checkAvailable: Bool = true)
        async throws
    {
        if checkAvailable && status == .speakersUnavailable {
            throw KHAccessError.speakersNotReachable
        }
        // TODO send command
        let RX = ""
        if RX.starts(with: "{\"osc\":{\"error\"") {
            if RX.contains("404") {
                throw KHAccessError.addressNotFound
            }
            if RX.contains("400") {
                throw KHAccessError.messageNotUnderstood
            }
        }
    }

    private func sendSSCCommand(path: [String], value: Any, checkAvailable: Bool = true)
        async throws
    {
        /// sends the command `{"p1":{"p2":{String(describing: value)}}` to the device, if
        /// `path=["p1", "p2"]`.
        var jsonPath = String(describing: value)
        for p in path.reversed() {
            jsonPath = "{\"\(p)\":\(jsonPath)}"
        }
        jsonPath = "'" + jsonPath + "'"
        let _ = device.sendMessage(jsonPath)
    }

    func checkSpeakersAvailable() async throws {
        guard let khtoolJsonURL = Bundle.main.url(
            forResource: "khtool", withExtension: "json")
        else {
            print("khtool.json does not exist. This should not happen.")
            throw KHAccessError.fileError
        }
        let data = try Data(contentsOf: khtoolJsonURL)
        let deviceDict = try JSONDecoder().decode([String: String].self, from: data)
        // If we don't do this, khtool.py will just do nothing.
        if deviceDict.isEmpty {
            status = .scanning
            try await runKHToolProcess(args: ["--scan"], checkAvailable: false)
            guard let khtoolJsonURL = Bundle.main.url(
                forResource: "khtool", withExtension: "json")
            else {
                print("Scan did not produce khtool.json. This should not happen.")
                status = .noSpeakersFoundDuringScan
                throw KHAccessError.fileError
            }
            let data = try Data(contentsOf: khtoolJsonURL)
            let deviceDict = try JSONDecoder().decode(
                [String: String].self, from: data)
            if deviceDict.isEmpty {
                status = .noSpeakersFoundDuringScan
            } else {
                status = .clean
                try await backupAndFetch()
            }
        } else {
            status = .checkingSpeakerAvailability
            do {
                try await sendSSCCommand(path: ["osc", "ping"], value: 0, checkAvailable: false)
            } catch KHAccessError.processError {
                // this happens only when "device is not online", not when 0 devices are
                // found during scan.
                status = .speakersUnavailable
            }
            status = .clean
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

    private func sendVolumeToDevice() async throws {
        try await runKHToolProcess(args: ["--level", "\(Int(volume))"])
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
        // nope it just works
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
    }
}

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

    // (last known) device state. We compare UI state against this to selectively send
    // changed values to the device.
    private var volumeDevice = 54.0
    private var eqsDevice = [Eq(numBands: 10), Eq(numBands: 20)]
    private var mutedDevice = false
    private var logoBrightnessDevice = 100.0

    var status: Status = .clean
    var devices: [SSCDevice]

    init(devices devices_: [SSCDevice]? = nil) {
        if let devices_ = devices_ {
            devices = devices_
            return
        } else {
            devices = SSCDevice.scan()
        }
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

    static func pathToJSONString<T>(path: [String], value: T) throws -> String
    where T: Encodable {
        let jsonData = try JSONEncoder().encode(value)
        var jsonPath = String(data: jsonData, encoding: .utf8)!
        for p in path.reversed() {
            jsonPath = "{\"\(p)\":\(jsonPath)}"
        }
        return jsonPath
    }

    private func sendSSCCommand(command: String, checkAvailable: Bool = true)
        throws -> SSCTransaction
    {
        if checkAvailable && status == .speakersUnavailable {
            throw KHAccessError.speakersNotReachable
        }
        let transactions = devices.map { d in d.sendMessage(command) }
        for t in transactions {
            let deadline = Date.now.addingTimeInterval(5)
            var success = false
            while Date.now < deadline {
                if !t.RX.isEmpty {
                    success = true
                    break
                }
            }
            if !success {
                print("No response from speaker")
                status = .speakersUnavailable
                throw KHAccessError.speakersNotReachable
            }

        }
        let RX = transactions[0].RX
        if RX.starts(with: "{\"osc\":{\"error\"") {
            if RX.contains("404") {
                throw KHAccessError.addressNotFound
            }
            if RX.contains("400") {
                throw KHAccessError.messageNotUnderstood
            }
        }
        return transactions[0]
    }

    func sendSSCValue<T>(path: [String], value: T, checkAvailable: Bool = true)
        throws where T: Encodable
    {
        /// sends the command `{"p1":{"p2":value}}` to the device, if `path=["p1", "p2"]`.
        let jsonPath = try KHAccess.pathToJSONString(path: path, value: value)
        try _ = sendSSCCommand(
            command: jsonPath, checkAvailable: checkAvailable)
    }

    func fetchSSCValue<T>(path: [String], checkAvailable: Bool = true) throws -> T
    where T: Decodable {
        let jsonPath = try KHAccess.pathToJSONString(path: path, value: nil as Float?)
        let transaction = try sendSSCCommand(
            command: jsonPath, checkAvailable: checkAvailable)
        let RX = transaction.RX
        let asObj = try JSONSerialization.jsonObject(with: RX.data(using: .utf8)!)
        let lastKey = path.last!
        var result: [String: Any] = asObj as! [String: Any]
        for p in path.dropLast() {
            result = result[p] as! [String: Any]
        }
        return result[lastKey] as! T
    }

    func checkSpeakersAvailable() async throws {
        print(devices.isEmpty)
        status = .checkingSpeakerAvailability
        if devices.isEmpty {
            status = .scanning
            devices = SSCDevice.scan()
            if devices.isEmpty {
                status = .noSpeakersFoundDuringScan
                return
            } else {
                status = .clean
                try await fetch()
            }
        }
        for d in devices {
            if d.connection.state != .ready {
                print("connecting")
                d.connect()
            }
            let deadline = Date.now.addingTimeInterval(5)
            var success = false
            while Date.now < deadline {
                if d.connection.state == .ready {
                    success = true
                    break
                }
            }
            if !success {
                print("timed out, could not connect")
                status = .speakersUnavailable
                throw KHAccessError.speakersNotReachable
            }
            print("connected")
        }
        status = .clean
        try await fetch()
    }
    
    /*
     DUMB AND BORING STUFF BELOW THIS COMMENT
     
     There must be a better way to do this. Create a struct with the UI values and
     associate a path to each one somehow. The values should know how to fetch
     themselves or something so we can add them more easily and modularly.
     */

    func fetch() async throws {
        status = .fetching

        volumeDevice = try fetchSSCValue(path: ["audio", "out", "level"])
        mutedDevice = try fetchSSCValue(path: ["audio", "out", "mute"])
        logoBrightnessDevice = try fetchSSCValue(path: ["ui", "logo", "brightness"])
        for (eqIdx, eqName) in ["eq2", "eq3"].enumerated() {
            eqsDevice[eqIdx].boost = try fetchSSCValue(path: [
                "audio", "out", eqName, "boost",
            ])
            eqsDevice[eqIdx].enabled = try fetchSSCValue(path: [
                "audio", "out", eqName, "enabled",
            ])
            eqsDevice[eqIdx].frequency = try fetchSSCValue(path: [
                "audio", "out", eqName, "frequency",
            ])
            eqsDevice[eqIdx].gain = try fetchSSCValue(path: [
                "audio", "out", eqName, "gain",
            ])
            eqsDevice[eqIdx].q = try fetchSSCValue(path: [
                "audio", "out", eqName, "q",
            ])
            eqsDevice[eqIdx].type = try fetchSSCValue(path: [
                "audio", "out", eqName, "type",
            ])
        }
        volume = volumeDevice
        muted = mutedDevice
        logoBrightness = logoBrightnessDevice
        eqs = eqsDevice

        status = .clean
    }

    private func sendVolumeToDevice() async throws {
        //try await runKHToolProcess(args: ["--level", "\(Int(volume))"])
        try sendSSCValue(path: ["audio", "out", "level"], value: Int(volume))
    }

    private func sendEqBoost(eqIdx: Int, eqName: String) async throws {
        try sendSSCValue(
            path: ["audio", "out", eqName, "boost"], value: eqs[eqIdx].boost)
    }

    private func sendEqEnabled(eqIdx: Int, eqName: String) async throws {
        try sendSSCValue(
            path: ["audio", "out", eqName, "enabled"], value: eqs[eqIdx].enabled)
    }

    private func sendEqFrequency(eqIdx: Int, eqName: String) async throws {
        try sendSSCValue(
            path: ["audio", "out", eqName, "frequency"], value: eqs[eqIdx].frequency)
    }

    private func sendEqGain(eqIdx: Int, eqName: String) async throws {
        try sendSSCValue(
            path: ["audio", "out", eqName, "gain"], value: eqs[eqIdx].gain)
    }

    private func sendEqQ(eqIdx: Int, eqName: String) async throws {
        try sendSSCValue(
            path: ["audio", "out", eqName, "q"], value: eqs[eqIdx].q)
    }

    private func sendEqType(eqIdx: Int, eqName: String) async throws {
        try sendSSCValue(
            path: ["audio", "out", eqName, "type"], value: eqs[eqIdx].type)
    }

    private func sendMuteOrUnmute() async throws {
        try sendSSCValue(path: ["audio", "out", "mute"], value: muted)
    }

    private func sendLogoBrightness() async throws {
        /// We don't want to use the `--brightness` option because it can't take floats (although we don't either)
        /// and it only goes up to 100 even though the real brightness goes up to 125.
        try sendSSCValue(
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

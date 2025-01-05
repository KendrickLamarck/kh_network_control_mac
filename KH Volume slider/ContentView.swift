//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI


struct ContentView: View {
    // This should really read out the actual current volume...
    @State private var volume: Double = 54
    @State private var fetchButtonlabel: String = "Fetch"
    @State private var sendingEqSettings: Bool = false
    
    // TODO this seemed like a good idea at the time, but maybe this should
    // have the same structure as the json commands.
    struct EqBand: Identifiable, Hashable {
        var index: Int
        var boost: Double = 0
        var enabled: Bool = false
        var frequency: Double = 100
        var gain: Double = 0
        var q: Double = 0.7
        var type: EqType = EqType.parametric
        
        enum EqType: String, CaseIterable, Identifiable {
            case parametric = "PARAMETRIC"
            case loshelf = "LOSHELF"
            case hishelf = "HISHELF"
            case lowpass = "LOWPASS"
            case highpass = "HIGHPASS"
            case bandpass = "BANDPASS"
            case notch = "NOTCH"
            case allpass = "ALLPASS"
            case hi6db = "HI6DB"
            case lo6db = "LO6DB"
            case inversion = "INVERSION"
            var id: String { self.rawValue }
        }

        var id: Int { index }
    }

    @State private var eqBands: [EqBand] = (0..<20).map { i in EqBand(index: i) }
    // @State private var selectedEqBand: EqBand = EqBand(index: -1)
    @State private var selectedEqBand: Int = 0

    private var scriptPath = URL(filePath: "/Users/lblume/code/kh_120/")

    init() {
        // This makes the startup really slow. Not good.
        // I have no idea what this underscore is and why we have to do this here but
        // we can just set the value normally in the body.
        //_volume = State(initialValue: self.getVolume())
    }

    var body: some View {
        VStack {
            Text("Monitor volume")
            Slider(value: $volume, in: 0...120, step: 6) {
                Text("")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("120")
            } onEditingChanged: { editing in
                guard (!editing) else {
                    return
                }
                setVolume(volume: volume)
            }
            // We don't want to run this every time the window opens, only once. But how?
            //.task {
            //    await fetchVolume()
            //}
            Text("\(Int(volume)) dB")
            
            if fetchButtonlabel == "Fetching..." {
                ProgressView().scaleEffect(0.5).frame(height: 20)
            } else {
                Button(fetchButtonlabel) {
                    Task {
                        fetchButtonlabel = "Fetching..."
                        await createBackup()
                        fetchVolume()
                        fetchEq()
                        fetchButtonlabel = "Fetch"
                    }
                }
                .frame(height: 20)
            }
            
            Divider()
            
            HStack {
                Picker("EQ Band:", selection: $selectedEqBand) {
                    ForEach(eqBands) { band in
                        Text("\(band.index + 1)")
                    }
                }
                .frame(width: 100)
                Picker("Type:", selection: $eqBands[selectedEqBand].type) {
                    ForEach(EqBand.EqType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .frame(width: 160)
                Toggle("Enable", isOn: $eqBands[selectedEqBand].enabled)
            }
            Slider(value: $eqBands[selectedEqBand].boost, in: -99...24)
            Text("Boost: \(eqBands[selectedEqBand].boost, specifier: "%.1f") dB")
            Slider(value: $eqBands[selectedEqBand].gain, in: -99...24)
            Text("Gain: \(eqBands[selectedEqBand].gain, specifier: "%.1f") dB")
            Slider(value: $eqBands[selectedEqBand].frequency, in: 10...24000)
            Text("Frequency: \(eqBands[selectedEqBand].frequency, specifier: "%.1f") Hz")
            Slider(value: $eqBands[selectedEqBand].q, in: 0.1...16)
            Text("Q: \(eqBands[selectedEqBand].q, specifier: "%.1f")")
            
            if sendingEqSettings {
                ProgressView().scaleEffect(0.5).frame(height: 20)
            } else {
                Button("Send EQ Settings") {
                    Task {
                        sendingEqSettings = true
                        await sendEqSettings()
                        sendingEqSettings = false
                    }
                }
            }
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(height: 400)
    }
    
    func createKHToolProcess(args: [String] = []) -> Process {
        let process = Process()
        process.executableURL = URL(filePath: "/bin/sh")
        process.currentDirectoryURL = scriptPath
        var argString = ""
        for arg in args {
            argString += " \(arg)"
        }
        process.arguments =
        ["-c",
         "./.venv/bin/python"
         + " /Users/lblume/code/kh_120/khtool/khtool.py -i en0" + argString]
        return process
    }
    
    func setVolume(volume: Double) {
        let process = createKHToolProcess(args: ["--level", "\(Int(volume))"])
        try! process.run()
    }

    func createBackup() async {
        let backupPath = scriptPath.path + "/backup.json"
        let process = createKHToolProcess(args: ["--backup", backupPath])
        try! process.run()
        process.waitUntilExit()
    }
    
    struct KHJSON: Codable {
        var devices: [String: Device]

        struct Device: Codable {
            var product: String
            var serial: String
            var version: String
            var commands: Commands
            
            struct Commands: Codable {
                var audio: Audio
                
                struct Audio: Codable {
                    var out: Outparams

                    struct Outparams: Codable {
                        var level: Double
                        var eq3: Eq
                        
                        struct Eq: Codable {
                            var boost: [Double]
                            var enabled: [Bool]
                            var frequency: [Double]
                            var gain: [Double]
                            var q: [Double]
                            var type: [String]
                        }
                    }
                }
            }
        }
    }
    
    func backupAsStruct() -> KHJSON? {
        let backupPath = scriptPath.path + "/backup.json"
        guard let data = try? Data(contentsOf: URL(filePath: backupPath)) else {
            return nil
        }
        return try? JSONDecoder().decode(KHJSON.self, from: data)
    }
    
    func getVolume() -> Double? {
        let json = backupAsStruct()
        return json?.devices.values.first?.commands.audio.out.level
    }
    
    func fetchVolume() {
        guard let new_volume = getVolume() else {
            print("fetching volume failed")
            return
        }
        volume = new_volume
    }
    
    func fetchEq() {
        let json = backupAsStruct()
        guard let eq = json?.devices.values.first?.commands.audio.out.eq3 else {
            return
        }
        for i in 0..<20 {
            eqBands[i].boost = eq.boost[i]
            eqBands[i].enabled = eq.enabled[i]
            eqBands[i].frequency = eq.frequency[i]
            eqBands[i].gain = eq.gain[i]
            eqBands[i].q = eq.q[i]
            eqBands[i].type = EqBand.EqType(rawValue: eq.type[i]) ?? EqBand.EqType.parametric
        }
    }
        
    func updateKhjsonWithEq(_ data: KHJSON) -> KHJSON {
        guard var eq = data.devices.values.first?.commands.audio.out.eq3 else {
            return data
        }
        var new_data = data
        for i in 0..<20 {
            eq.boost[i] = eqBands[i].boost
            eq.enabled[i] = eqBands[i].enabled
            eq.frequency[i] = eqBands[i].frequency
            eq.gain[i] = eqBands[i].gain
            eq.q[i] = eqBands[i].q
            eq.type[i] = eqBands[i].type.rawValue
        }
        for k in new_data.devices.keys {
            new_data.devices[k]?.commands.audio.out.eq3 = eq
        }
        return new_data
    }
    
    func writeKHJSON(_ data: KHJSON, filename: String) {
        let backupPath = scriptPath.appendingPathComponent(filename)
        let jsonString = try? JSONEncoder().encode(data)
        do {
            try jsonString?.write(to: backupPath)
        } catch {
            print("Writing file failed.")
        }
    }
    
    func sendEqSettings() async {
        await createBackup()
        guard let data = backupAsStruct() else {
            print("Failed to read backup file")
            return
        }
        let updatedData = updateKhjsonWithEq(data)
        // TODO we might not even need to do this with an intermediary file. We can try
        // sending the message with --expert.
        /*
        guard let jsonData = try? JSONEncoder().encode(updatedData) else {
            return
        }
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        let process = createKHToolProcess(args: ["--expert", jsonString])
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error while sending eq settings to device.")
        }
         */
        let filename = "eq_settings.json"
        writeKHJSON(updatedData, filename: filename)
        let backupPath = scriptPath.appendingPathComponent(filename)
        let process = createKHToolProcess(args: ["--restore", backupPath.path()])
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error while sending eq settings to device.")
        }
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI


struct ContentView: View {
    @State private var volume: Double = 54
    @State private var fetchButtonlabel: String = "Fetch"
    @State private var sendingEqSettings: Bool = false
    //@State private var eqBands2: [EqBand] = (0..<10).map { i in EqBand(index: i) }
    // Really eqBands3
    //@State private var eqBands: [EqBand] = (0..<20).map { i in EqBand(index: i) }
    @State private var eqs: [[EqBand]] = [
        (0..<10).map { i in EqBand(index: i) },
        (0..<20).map { i in EqBand(index: i) }
    ]
    @State private var selectedEq: Int = 0
    @State private var selectedEqBand: Int = 0
    
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
                        var level: Double?
                        var eq2: Eq
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
            .task {
                await createBackup()
                fetchVolume()
                fetchEq()
            }
            Text("\(Int(volume)) dB")
                        
            Divider()
            
            Picker("EQ:", selection: $selectedEq) {
                Text("eq2").tag(0)
                Text("eq3").tag(1)
            }
            .frame(width: 150)
            .onChange(of: selectedEq) {
                // not enough
                selectedEqBand = 0
            }

            
            HStack {
                Picker("EQ Band:", selection: $selectedEqBand) {
                    ForEach(eqs[selectedEq]) { band in
                        Text("\(band.index + 1)")
                    }
                }.frame(width: 120)
                Picker("Type:", selection: $eqs[selectedEq][selectedEqBand].type) {
                    ForEach(EqBand.EqType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }.frame(width: 160)
                Toggle("Enabled", isOn: $eqs[selectedEq][selectedEqBand].enabled)
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
            }
            Grid(alignment: .topLeading) {
                // TODO ForEach
                GridRow {
                    Text("Frequency (Hz):")
                    Slider(value: $eqs[selectedEq][selectedEqBand].frequency, in: 10...24000)
                    TextField(
                        "Frequency",
                        value: $eqs[selectedEq][selectedEqBand].frequency,
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
                GridRow {
                    Text("Boost (dB):")
                    Slider(value: $eqs[selectedEq][selectedEqBand].boost, in: -99...24)
                    TextField(
                        "Boost",
                        value: $eqs[selectedEq][selectedEqBand].boost,
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
                GridRow {
                    Text("Q:")
                    Slider(value: $eqs[selectedEq][selectedEqBand].q, in: 0.1...16)
                    TextField(
                        "Q",
                        value: $eqs[selectedEq][selectedEqBand].q,
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
                GridRow {
                    Text("Gain (dB):")
                    Slider(value: $eqs[selectedEq][selectedEqBand].gain, in: -99...24)
                    TextField(
                        "Gain",
                        value: $eqs[selectedEq][selectedEqBand].gain,
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
            }

            Divider()

            HStack {
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
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
        }
        .padding()
        .frame(width: 550)
    }
    
    func createKHToolProcess(args: [String] = []) -> Process {
        let process = Process()
        process.executableURL = URL(filePath: "/bin/sh")
        process.currentDirectoryURL = scriptPath
        var argString = ""
        for arg in args {
            argString += " " + arg
        }
        process.arguments =
        ["-c",
         "./.venv/bin/python"
         + " ./khtool/khtool.py -i en0" + argString]
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
        guard let out = json?.devices.values.first?.commands.audio.out else {
            return
        }
        for (j, eq) in [out.eq2, out.eq3].enumerated() {
            for i in 0..<eqs[j].count {
                eqs[j][i].boost = eq.boost[i]
                eqs[j][i].enabled = eq.enabled[i]
                eqs[j][i].frequency = eq.frequency[i]
                eqs[j][i].gain = eq.gain[i]
                eqs[j][i].q = eq.q[i]
                eqs[j][i].type = EqBand.EqType(rawValue: eq.type[i]) ?? EqBand.EqType.parametric
            }
        }
    }
        
    func updateKhjsonWithEq(_ data: KHJSON) -> KHJSON {
        var new_data = data
        guard let out = new_data.devices.values.first?.commands.audio.out else {
            print("updating KHJSON with eq failed")
            return data
        }
        var new_data_eqs = [out.eq2, out.eq3]
        for j in 0..<eqs.count {
            for i in 0..<eqs[j].count {
                new_data_eqs[j].boost[i] = eqs[j][i].boost
                new_data_eqs[j].enabled[i] = eqs[j][i].enabled
                new_data_eqs[j].frequency[i] = eqs[j][i].frequency
                new_data_eqs[j].gain[i] = eqs[j][i].gain
                new_data_eqs[j].q[i] = eqs[j][i].q
                new_data_eqs[j].type[i] = eqs[j][i].type.rawValue
            }
        }
        for k in new_data.devices.keys {
            new_data.devices[k]?.commands.audio.out.eq2 = new_data_eqs[0]
            new_data.devices[k]?.commands.audio.out.eq3 = new_data_eqs[1]
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
        guard let data = backupAsStruct() else {
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

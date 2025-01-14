//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI

struct Eq: Codable {
    var boost: [Double]
    var enabled: [Bool]
    var frequency: [Double]
    var gain: [Double]
    var q: [Double]
    var type: [String]

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
                }
            }
        }
    }
}

// currently unused. Have to figure out how to iterate over eq properties or find a
// different solution.
struct EqSlider: View {
    var name: String
    var unit: String
    var range: ClosedRange<Double>

    @State var eqs: [Eq]
    @State var selectedEq: Int = 0
    @State var selectedEqBand: Int = 0
    
    var body: some View {
        Text("\(name) (\(unit))")
        Slider(value: $eqs[selectedEq].frequency[selectedEqBand], in: range)
        TextField(
            "Frequency",
            value: $eqs[selectedEq].frequency[selectedEqBand],
            format: .number.precision(.fractionLength(1))
        ).frame(width:80)
    }
}


struct ContentView: View {
    private var scriptPath: URL
    private var pythonPath: URL
    private var khtoolPath: URL
    private var networkInterface: String

    @State internal var volume: Double = 54
    @State private var fetching: Bool = false
    @State private var sendingEqSettings: Bool = false
    @State private var eqs: [Eq] = [10, 20].map({numBands in
        Eq(
            boost: Array(repeating: 0.0, count: numBands),
            enabled: Array(repeating: false, count: numBands),
            frequency: Array(repeating: 100.0, count: numBands),
            gain: Array(repeating: 0.0, count: numBands),
            q: Array(repeating: 0.71, count: numBands),
            type: Array(repeating: Eq.EqType.parametric.rawValue, count: numBands)
        )
    })
    @State private var selectedEq: Int = 0
    @State private var selectedEqBand: Int = 0
    
    init() {
        // ####### SET THESE VARIABLES #######################################
        self.scriptPath = URL.homeDirectory.appending(path: "code/kh_120")
        self.pythonPath = self.scriptPath.appending(path: ".venv/bin/python")
        self.khtoolPath = self.scriptPath.appending(path: "khtool/khtool.py")
        self.networkInterface = "en0"
        // ###################################################################
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
                guard !editing else {
                    return
                }
                sendVolumeToDevice()
            }
            // We don't want to run this every time the window opens, only once. But how?
            .task {
                await backupAndFetch()
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
                    ForEach((1...eqs[selectedEq].boost.count), id: \.self) { i in
                        Text("\(i)").tag(i - 1)
                    }
                }.frame(width: 120)
                Picker("Type:", selection: $eqs[selectedEq].type[selectedEqBand]) {
                    ForEach(Eq.EqType.allCases) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }.frame(width: 160)
                Toggle("Enabled", isOn: $eqs[selectedEq].enabled[selectedEqBand])
                if sendingEqSettings {
                    Text("Sending...")
                    ProgressView().scaleEffect(0.5).frame(height: 20)
                } else {
                    Button("Send EQ Settings") {
                        Task {
                            sendingEqSettings = true
                            await sendEqToDevice()
                            sendingEqSettings = false
                        }
                    }
                }
            }
            Grid(alignment: .topLeading) {
                // TODO ForEach
                GridRow {
                    Text("Frequency (Hz):")
                    Slider(value: $eqs[selectedEq].frequency[selectedEqBand], in: 10...24000)
                    TextField(
                        "Frequency",
                        value: $eqs[selectedEq].frequency[selectedEqBand],
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
                GridRow {
                    Text("Boost (dB):")
                    Slider(value: $eqs[selectedEq].boost[selectedEqBand], in: -99...24)
                    TextField(
                        "Boost",
                        value: $eqs[selectedEq].boost[selectedEqBand],
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
                GridRow {
                    Text("Q:")
                    Slider(value: $eqs[selectedEq].q[selectedEqBand], in: 0.1...16)
                    TextField(
                        "Q",
                        value: $eqs[selectedEq].q[selectedEqBand],
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
                GridRow {
                    Text("Gain (dB):")
                    Slider(value: $eqs[selectedEq].gain[selectedEqBand], in: -99...24)
                    TextField(
                        "Gain",
                        value: $eqs[selectedEq].gain[selectedEqBand],
                        format: .number.precision(.fractionLength(1))
                    ).frame(width:80)
                }
            }

            Divider()

            HStack {
                if fetching {
                    Text("Fetching...")
                    ProgressView().scaleEffect(0.5).frame(height: 20)
                } else {
                    Button("Fetch") {
                        Task {
                            await backupAndFetch()
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
    
    func createKHToolProcess(args: [String]) -> Process {
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
        return process
    }

    func backupDevice() async {
        let backupPath = scriptPath.appending(path: "gui_backup.json")
        let process = createKHToolProcess(args: ["--backup", backupPath.path])
        try! process.run()
        process.waitUntilExit()
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
        fetching = true
        await backupDevice()
        readVolumeFromBackup()
        readEqFromBackup()
        fetching = false
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
    
    func writeKHJSONToFile(_ data: KHJSON, filename: String) {
        let backupPath = scriptPath.appending(path: filename)
        let jsonString = try? JSONEncoder().encode(data)
        do {
            try jsonString?.write(to: backupPath)
        } catch {
            print("Writing file failed.")
        }
    }
    
    func sendVolumeToDevice() {
        let process = createKHToolProcess(args: ["--level", "\(Int(volume))"])
        try! process.run()
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
        // TODO does this file need to persist or can we delete it after sending the settings?
        let filename = "gui_eq_settings.json"
        writeKHJSONToFile(updatedData, filename: filename)
        let backupPath = scriptPath.appending(path: filename)
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

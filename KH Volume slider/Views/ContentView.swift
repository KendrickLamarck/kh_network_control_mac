//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI

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
                if !editing {
                    Task {
                        await sendVolumeToDevice()
                    }
                }
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
                let sliders: [EqSlider.SliderData] = [
                    EqSlider.SliderData(
                        binding: $eqs[selectedEq].frequency,
                        name: "Frequency",
                        unit: "Hz",
                        range: 10...24000
                    ),
                    EqSlider.SliderData(
                        binding: $eqs[selectedEq].boost,
                        name: "Boost",
                        unit: "dB",
                        range: -99...24
                    ),
                    EqSlider.SliderData(
                        binding: $eqs[selectedEq].q,
                        name: "Q",
                        unit: nil,
                        range: 0.1...16
                    ),
                    EqSlider.SliderData(
                        binding: $eqs[selectedEq].gain,
                        name: "Gain",
                        unit: "dB",
                        range: -99...24
                    )
                ]
                ForEach(sliders) { sliderdata in
                    GridRow {
                        EqSlider(
                            binding: sliderdata.binding,
                            name: sliderdata.name,
                            unit: sliderdata.unit,
                            range: sliderdata.range,
                            eqs: eqs,
                            selectedEq: selectedEq,
                            selectedEqBand: selectedEqBand
                        )
                    }
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
    
    func runKHToolProcess(args: [String]) async throws {
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
            try process.run()
            process.waitUntilExit()
        } catch {
            // TODO print process output with pipe or something
            print("Process failed.")
        }
    }

    func backupDevice() async {
        let backupPath = scriptPath.appending(path: "gui_backup.json")
        try? await runKHToolProcess(args: ["--backup", backupPath.path])
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
    
    func sendVolumeToDevice() async {
        try? await runKHToolProcess(args: ["--level", "\(Int(volume))"])
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
        try? await runKHToolProcess(args: ["--restore", backupPath.path])
    }
}

#Preview {
    ContentView()
}

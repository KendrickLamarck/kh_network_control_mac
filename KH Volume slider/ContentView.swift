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
    
    struct EqBand {
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
    }
    
    @State private var eqBands: [EqBand] = [EqBand(), EqBand()]
    
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
            Button(fetchButtonlabel) {
                Task {
                    await fetchVolume()
                }
            }
            Divider()
            Slider(value: $eqBands[0].boost, in: -99...24) {
                Text("Boost: \(eqBands[0].boost, specifier: "%.1f") dB")
            }
            Slider(value: $eqBands[0].gain, in: -99...24) {
                Text("Gain: \(eqBands[0].gain, specifier: "%.1f") dB")
            }
            Slider(value: $eqBands[0].frequency, in: 10...24000) {
                Text("Frequency: \(eqBands[0].frequency, specifier: "%.1f") Hz")
            }
            Slider(value: $eqBands[0].q, in: 0.1...16) {
                Text("Q: \(eqBands[0].q, specifier: "%.1f")")
            }
            Toggle("Enable", isOn: $eqBands[0].enabled)
            Picker("Type", selection: $eqBands[0].type) {
                Text("Parametric").tag(EqBand.EqType.parametric)
                Text("Lo shelf").tag(EqBand.EqType.loshelf)
                Text("Hi shelf").tag(EqBand.EqType.hishelf)
                Text("Low pass").tag(EqBand.EqType.lowpass)
                Text("High pass").tag(EqBand.EqType.highpass)
                Text("Band pass").tag(EqBand.EqType.bandpass)
                Text("Notch").tag(EqBand.EqType.notch)
                Text("All pass").tag(EqBand.EqType.allpass)
                Text("Hi 6 dB").tag(EqBand.EqType.hi6db)
                Text("Lo 6 dB").tag(EqBand.EqType.lo6db)
                Text("Inversion").tag(EqBand.EqType.inversion)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
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
    
    struct KHJSON: Decodable {
        let devices: [String: Device]

        struct Device: Decodable {
            let commands: Commands
            
            struct Commands: Decodable {
                let audio: Audio
                
                struct Audio: Decodable {
                    let out: Outparams

                    struct Outparams: Decodable {
                        let level: Double
                        let eq3: Eq
                        
                        struct Eq: Decodable {
                            let boost: [Double]
                            let enabled: [Bool]
                            let frequency: [Double]
                            let gain: [Double]
                            let q: [Double]
                            let type: [String]
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
    
    func getVolume() async -> Double? {
        await createBackup()
        let json = backupAsStruct()
        return json?.devices.values.first?.commands.audio.out.level
    }
    
    func fetchVolume() async {
        fetchButtonlabel = "Fetching..."
        guard let new_volume = await getVolume() else {
            fetchButtonlabel = "Fetching failed"
            return
        }
        fetchButtonlabel = "Fetch"
        volume = new_volume
    }
}

#Preview {
    ContentView()
}

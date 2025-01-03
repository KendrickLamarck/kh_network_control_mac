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
    private var scriptPath = URL(filePath: "/Users/lblume/code/kh_120/")

    init() {
        // This makes the startup really slow. Not good.
        // I have no idea what this underscore is and why we have to do this here but
        // we can just set the value normally in the body.
        _volume = State(initialValue: self.getVolume())
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
            Text("\(Int(volume)) dB")
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            Button("Fetch") {
                volume = getVolume()
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
    
    func getVolume() -> Double {
        let backupPath = scriptPath.path + "/backup.json"
        let process = createKHToolProcess(args: ["--backup", backupPath])
        try! process.run()
        // TODO make this async or something and block slider editing while this runs.
        process.waitUntilExit()
        
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
                        }
                    }
                }
            }
        }

        do {
            let data = try Data(contentsOf: URL(filePath: backupPath))
            let json = try JSONDecoder().decode(KHJSON.self, from: data)
            let level = json.devices.values.first?.commands.audio.out.level
            return level ?? 54
        } catch {
            print("\(error.localizedDescription)")
            return -1
        }
    }
}

#Preview {
    ContentView()
}

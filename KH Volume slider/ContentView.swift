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
            Button("Quit") { NSApplication.shared.terminate(nil) } // looks horrible, works.
            Button("Fetch") { getVolume() }
        }
        .padding()
        // .frame(width: 300, height: 150)
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
    
    func getVolume() {
        let backupPath = scriptPath.path + "/backup.json"
        let process = createKHToolProcess(args: ["--backup", backupPath])
        try! process.run()
        struct KHJSON: Decodable {
            let devices: [String: Device]
            
            struct Device: Decodable {
                let commands: [String]
            }
        }
        do {
            let data = try Data(contentsOf: URL(filePath: backupPath))
            let json = try JSONDecoder().decode(KHJSON.self, from: data)
            print(json)
        } catch {
            print("Error while reading json file.")
        }
    }
}

#Preview {
    ContentView()
}

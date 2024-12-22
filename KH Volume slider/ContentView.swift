//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI

struct ContentView: View {
    @State private var volume: Double = 55

    var body: some View {
        VStack {
            Text("KH 120 II volume")
            Slider(value: $volume, in: 0...120, step: 5) {
                Text("")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("120")
            }
            Text("\(Int(volume)) dB")
        }
        .padding()
        .onChange(of: volume) {
            // Call Python script
            let process = Process()
            let pipe = Pipe()
            process.standardOutput = pipe
            process.executableURL = URL(filePath: "/bin/sh")
            process.currentDirectoryURL = URL(filePath: "/Users/lblume/code/kh_120/")
            process.arguments =
                ["-c",
                 "/opt/homebrew/bin/python3.9"
                     + " /Users/lblume/code/kh_120/khtool/khtool.py"
                     + " -i en0 --level \(Int(volume))"]
            try! process.run()
            Thread.sleep(forTimeInterval: 0.1) // this sucks but it works
        }
        .frame(width: 300, height: 80)
    }
}

#Preview {
    ContentView()
}

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
            Slider(value: $volume, in: 0...120, step: 1) {
                Text("")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("120")
            }
            Text("Volume: \(Int(volume))")
        }
        .padding()
        .onChange(of: volume) {
            // Call Python script
            let process = Process()
            let pipe = Pipe()
            process.standardOutput = pipe
            process.executableURL = URL(filePath: "/bin/sh")
            process.currentDirectoryURL = URL(filePath: "/Users/lblume/code/kh_120/")
            process.arguments = ["-c", "/opt/homebrew/bin/python3.9", "/Users/lblume/code/kh_120/khtool/khtool.py",
                                 "-i", "en0",
                                 "--level", "\(Int(volume))"]
            try! process.run()
        }
        .frame(width: 300, height: 100)

    }
}

#Preview {
    ContentView()
}

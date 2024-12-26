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
                // Call Python script
                let process = Process()
                // We can't call python directly for some reason. Also needed to disable the app sandbox in the entitlement file or something to make this work.
                process.executableURL = URL(filePath: "/bin/sh")
                process.currentDirectoryURL = URL(filePath: "/Users/lblume/code/kh_120/")
                process.arguments =
                    ["-c",
                     "/opt/homebrew/bin/python3.9"
                         + " /Users/lblume/code/kh_120/khtool/khtool.py"
                         + " -i en0 --level \(Int(volume))"]
                try! process.run()
            }
            Text("\(Int(volume)) dB")
        }
        .padding()
        .frame(width: 300, height: 80)
    }
}

#Preview {
    ContentView()
}

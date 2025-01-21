//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI

struct ContentView: View {
    @State var khAccess = KHAccess()

    var body: some View {
        VStack {
            Text("Monitor volume")
            Slider(value: $khAccess.volume, in: 0...120, step: 3) {
                Text("")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("120")
            } onEditingChanged: { editing in
                if !editing {
                    Task {
                        try await khAccess.sendVolumeToDevice()
                    }
                }
            }
            .disabled(khAccess.status == .speakersUnavailable)
            .task {
                try? await khAccess.checkSpeakersAvailable()
            }
            Text("\(Int(khAccess.volume)) dB")
            
            Toggle("Mute", systemImage: "speaker.slash.fill", isOn: $khAccess.muted)
                .toggleStyle(.button)
                .onChange(of: khAccess.muted) {
                    Task {
                        try await khAccess.muteOrUnmute()
                    }
                }

            Divider()
            
            EqPanel(khAccess: khAccess)
            
            Divider()

            HStack {
                Button("Check speaker availability") {
                    Task {
                        try await khAccess.checkSpeakersAvailable()
                    }
                }
                .disabled(khAccess.status == .checkingSpeakerAvailability)

                Button("Fetch") {
                    Task {
                        try await khAccess.backupAndFetch()
                    }
                }
                .disabled(khAccess.status == .fetching || khAccess.status == .speakersUnavailable)
                
                Button("Send EQ settings") {
                    Task {
                        try await khAccess.sendEqToDevice()
                    }
                }
                .disabled(khAccess.status == .sendingEqSettings || khAccess.status == .speakersUnavailable)
                
                Spacer()
                
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            HStack {
                Spacer()
                StatusDisplay(status: khAccess.status)
            }

        }
        .padding()
        .frame(width: 550)
        
    }
}

#Preview {
    ContentView()
}

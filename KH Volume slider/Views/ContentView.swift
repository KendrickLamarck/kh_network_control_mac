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
            TabView {
                Tab("Volume", systemImage: "speaker.wave.3") {
                    VolumeSlider(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                }
                Tab("EQ", systemImage: "equal") {
                    EqPanel(khAccess: khAccess).padding(.horizontal).padding(.bottom)
                }
                Tab("UI", systemImage: "paintpalette") {
                    UIView(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                }
            }
            .frame(minWidth: 450)

            VStack {
                HStack {
                    Button("Ping") {
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
                    .disabled(
                        khAccess.status == .fetching
                            || khAccess.status == .speakersUnavailable)

                    Button("Send EQ") {
                        Task {
                            try await khAccess.sendEqToDevice()
                        }
                    }
                    .disabled(
                        khAccess.status == .sendingEqSettings
                            || khAccess.status == .speakersUnavailable)

                    Spacer()

                    Button("Quit") {
                        NSApplication.shared.terminate(nil)
                    }
                }

                HStack {
                    StatusDisplay(status: khAccess.status)
                    Spacer()
                    SettingsLink()
                }
            }
        }
        .scenePadding()
    }
}

#Preview {
    ContentView()
}

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
                    VStack {
                        Text("\(Int(khAccess.volume)) dB")
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

                        Toggle(
                            "Mute", systemImage: "speaker.slash.fill",
                            isOn: $khAccess.muted
                        )
                        .toggleStyle(.button)
                        .onChange(of: khAccess.muted) {
                            Task {
                                try await khAccess.muteOrUnmute()
                            }
                        }
                    }.padding(.horizontal).padding(.bottom)
                }

                Tab("EQ", systemImage: "equal") {
                    EqPanel(khAccess: khAccess).padding(.horizontal).padding(.bottom)
                }

                Tab("UI", systemImage: "paintpalette") {
                    HStack {
                        Text("Logo brightness")
                        Slider(value: $khAccess.logoBrightness, in: 0...125) {
                            Text("")
                        } onEditingChanged: { editing in
                            if !editing {
                                Task {
                                    try await khAccess.setLogoBrightness()
                                }
                            }
                        }
                        .disabled(khAccess.status == .speakersUnavailable)

                        TextField(
                            "Logo brightness",
                            value: $khAccess.logoBrightness,
                            format: .number.precision(.fractionLength(0))
                        )
                        .frame(width: 80)
                        .onSubmit {
                            Task {
                                try await khAccess.setLogoBrightness()
                            }
                        }
                    }
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

//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI

typealias KHAccess = KHAccessNative

struct ContentView: View {
    @State var khAccess = KHAccess()

    var body: some View {
        VStack {
            TabView {
                Tab("Volume", systemImage: "speaker.wave.3") {
                    VolumeTab(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                        .disabled(khAccess.status != .clean)
                }
                Tab("DSP", systemImage: "equal") {
                    EqPanel(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                        .disabled(khAccess.status != .clean)
                }
                Tab("Hardware", systemImage: "paintpalette") {
                    HardwareTab(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                        .disabled(khAccess.status != .clean)
                }
            }
            #if os(macOS)
            .frame(minWidth: 450)
            #endif
            .onAppear {
                Task {
                    try await khAccess.checkSpeakersAvailable()
                }
            }
            #if os(macOS)
            Divider()

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
                            try await khAccess.fetch()
                        }
                    }
                    .disabled(
                        khAccess.status == .fetching
                            || khAccess.status == .speakersUnavailable
                    )

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
            #elseif os(iOS)
            HStack {
                Button("Ping") {
                    Task {
                        try await khAccess.checkSpeakersAvailable()
                    }
                }
                .disabled(khAccess.status == .checkingSpeakerAvailability)
                
                Spacer()
                
                StatusDisplay(status: khAccess.status)
                
                Spacer()
                
                Button("Fetch") {
                    Task {
                        try await khAccess.fetch()
                    }
                }
                .disabled(
                    khAccess.status == .fetching
                    || khAccess.status == .speakersUnavailable
                )
            }
            .padding()
            #endif
        }
        .scenePadding()
    }
}

#Preview {
    ContentView()
}

//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI
import Foundation


struct ContentView: View {
    @State var khAccess = KHAccess()

    var body: some View {
        VStack {
            #if os(iOS)
            HStack {
                Button("Fetch") {
                    Task {
                        try await khAccess.checkSpeakersAvailable()
                    }
                }
                .disabled(khAccess.status == .checkingSpeakerAvailability)

                Spacer()

                StatusDisplay(status: khAccess.status)
            }
            .scenePadding()
            #endif

            TabView {
                Tab("Volume", systemImage: "speaker.wave.3") {
                    VolumeTab(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                        .disabled(khAccess.status != .clean)
                }
                Tab("DSP", systemImage: "slider.vertical.3") {
                    EqPanel(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                        .disabled(khAccess.status != .clean)
                }
                Tab("Hardware", systemImage: "hifispeaker") {
                    HardwareTab(khAccess: khAccess)
                        .padding(.horizontal).padding(.bottom)
                        .disabled(khAccess.status != .clean)
                }
            }
            #if os(macOS)
            .scenePadding()
            .frame(minWidth: 450)
            #endif
            .onAppear {
                Task {
                    try await khAccess.checkSpeakersAvailable()
                }
            }
            .textFieldStyle(.roundedBorder)
            
            #if os(macOS)
            HStack {
                Button("Fetch") {
                    Task {
                        try await khAccess.checkSpeakersAvailable()
                    }
                }
                .disabled(khAccess.status == .checkingSpeakerAvailability)
                
                Spacer()
                
                StatusDisplay(status: khAccess.status)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            .padding([.leading, .bottom, .trailing])
            #endif
        }
        // .frame(maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}

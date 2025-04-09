//
//  ContentViewMobile.swift
//  KH Volume slider
//
//  Created by Leander Blume on 09.04.25.
//

import SwiftUI

struct ContentViewMobile: View {
    @State var khAccess = KHAccess()

    var body: some View {
        VStack {
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

            TabView {
                Tab("Volume", systemImage: "speaker.wave.3") {
                    VolumeTabMobile(khAccess: khAccess)
                        .disabled(khAccess.status != .clean)
                }
                Tab("DSP", systemImage: "equal") {
                    ScrollView {
                        EqPanelMobile(khAccess: khAccess)
                            .disabled(khAccess.status != .clean)
                    }
                }
                Tab("Hardware", systemImage: "paintpalette") {
                    HardwareTabMobile(khAccess: khAccess)
                        .disabled(khAccess.status != .clean)
                }
            }
            .onAppear {
                Task {
                    try await khAccess.checkSpeakersAvailable()
                }
            }
            .textFieldStyle(.roundedBorder)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    ContentViewMobile()
}

//
//  VolumeSlider.swift
//  KH Volume slider
//
//  Created by Leander Blume on 26.01.25.
//

import SwiftUI

struct VolumeSlider: View {
    @Bindable var khAccess: KHAccess

    var body: some View {
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
                    try await khAccess.sendMuteOrUnmute()
                }
            }
        }
    }
}

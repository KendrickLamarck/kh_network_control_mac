//
//  VolumeSlider.swift
//  KH Volume slider
//
//  Created by Leander Blume on 26.01.25.
//

import SwiftUI

struct VolumeTabMobile: View {
    @Bindable var khAccess: KHAccess

    var body: some View {
        VStack {
            Text("Volume (dB)")
            Slider(value: $khAccess.volume, in: 0...120, step: 3) {
                Text("")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("120")
            } onEditingChanged: { editing in
                if !editing {
                    Task {
                        try await khAccess.send()
                    }
                }
            }
            .disabled(khAccess.status == .speakersUnavailable)
            
            Text("\(Int(khAccess.volume))")

            Stepper("+/- 3 db", value: $khAccess.volume, in: 0...120, step: 3) {
                editing in
                if editing {
                    return
                }
                Task {
                    try await khAccess.send()
                }
            }
            
            Toggle(
                "Mute",
                systemImage: "speaker.slash.fill",
                isOn: $khAccess.muted
            )
            .toggleStyle(.button)
            .onChange(of: khAccess.muted) {
                Task {
                    try await khAccess.send()
                }
            }
            .disabled(khAccess.status == .speakersUnavailable)
        }
        .padding()
    }
}

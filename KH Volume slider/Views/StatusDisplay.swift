//
//  StatusDisplay.swift
//  KH Volume slider
//
//  Created by Leander Blume on 17.01.25.
//

import SwiftUI

struct StatusDisplay: View {
    var status: KHAccess.Status

    var body: some View {
        HStack {
            Group {
                switch status {
                case .clean:
                    Image(systemName: "circle.fill").foregroundColor(.green)
                case .fetching:
                    ProgressView().scaleEffect(0.5)
                case .sendingEqSettings:
                    ProgressView().scaleEffect(0.5)
                case .checkingSpeakerAvailability:
                    ProgressView().scaleEffect(0.5)
                case .speakersUnavailable:
                    Image(systemName: "circle.fill").foregroundColor(.red)
                }
            }
            .frame(height: 20)
            .frame(minWidth: 33)
            switch status {
            case .speakersUnavailable:
                Text("Speakers unavailable")
            case .checkingSpeakerAvailability:
                Text("Checking speaker availability...")
            case .sendingEqSettings:
                Text("Sending EQ settings...")
            case .fetching:
                Text("Fetching...")
            case .clean:
                EmptyView()
            }
        }
    }
}

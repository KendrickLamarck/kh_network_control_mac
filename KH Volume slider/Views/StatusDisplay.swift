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
            switch status {
            case .speakersUnavailable:
                Text("Speakers unavailable")
            case .noSpeakersFoundDuringScan:
                Text("No speakers found during scan")
            case .checkingSpeakerAvailability:
                Text("Checking speaker availability...")
            default:
                EmptyView()
            /*
            case .fetching:
                Text("Fetching...")
            case .scanning:
                Text("Scanning...")
             */

            Group {
                switch status {
                case .clean:
                    Image(systemName: "circle.fill").foregroundColor(.green)
                case .fetching:
                    ProgressView().scaleEffect(0.5)
                case .checkingSpeakerAvailability:
                    ProgressView().scaleEffect(0.5)
                case .speakersUnavailable:
                    Image(systemName: "circle.fill").foregroundColor(.red)
                case .scanning:
                    ProgressView().scaleEffect(0.5)
                case .noSpeakersFoundDuringScan:
                    Image(systemName: "circle.fill").foregroundColor(.red)
                }
            }
            .frame(height: 20)
            .frame(minWidth: 33)
            }
        }
    }
}

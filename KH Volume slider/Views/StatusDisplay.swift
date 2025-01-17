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
        switch status {
        case .speakersUnavailable:
            Label("Speakers not available", systemImage: "exclamationmark.triangle")
                .fontWeight(.bold)
                .padding(.vertical, 3)
                .padding(.horizontal, 6)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(lineWidth: 2).foregroundColor(.red))
        case .sendingEqSettings:
            Text("Sending EQ settings...")
            ProgressView().scaleEffect(0.5).frame(height: 20)
        case .fetching:
            Text("Fetching...")
            ProgressView().scaleEffect(0.5).frame(height: 20)
        case .clean:
            Text("Ready")
        }
    }
}

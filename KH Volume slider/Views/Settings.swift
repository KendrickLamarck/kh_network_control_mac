//
//  Settings.swift
//  KH Volume slider
//
//  Created by Leander Blume on 23.01.25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("pythonExecutable") private var pythonExecutable = "python3"
    @AppStorage("networkInterface") private var networkInterface = "en0"

    public var body: some View {
        Form {
            TextField(
                "Python executable",
                text: $pythonExecutable
            )
            TextField(
                "Network interface",
                text: $networkInterface
            )
        }
        .scenePadding()
        .frame(width: 350)
    }
}

#Preview {
    SettingsView()
}

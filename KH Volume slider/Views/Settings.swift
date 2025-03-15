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
        VStack {
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

            Divider()

            Button("Delete cached device information") {
                if let khtoolJsonPath = Bundle.main.url(
                    forResource: "khtool", withExtension: "json") {
                    do {
                        try "{}".write(to: khtoolJsonPath, atomically: true, encoding: .utf8)
                    } catch {
                        print("khtool.json could not be overwritten.")
                    }
                }
                if let khtoolCommandsPath = Bundle.main.url(
                    forResource: "khtool_commands", withExtension: "json") {
                    do {
                        try FileManager.default.removeItem(at: khtoolCommandsPath)
                    } catch {
                        print("khtool_commands.json could not be deleted.")
                    }
                }
                let guiBackupPath = Bundle.main.url(
                    forResource: "gui_backup", withExtension: "json")
                let guiEqSettingsPath = Bundle.main.url(
                    forResource: "gui_eq_settings", withExtension: "json")
                
                [guiBackupPath, guiEqSettingsPath].forEach { t in
                    guard t != nil else {
                        return
                    }
                    do {
                        try "".write(to: t!, atomically: true, encoding: .utf8)
                    } catch {
                        print("file \(String(describing: t)) could not be cleared.")
                    }
                    return
                }
            }
        }
        .scenePadding()
        .frame(width: 350)
    }
}

#Preview {
    SettingsView()
}

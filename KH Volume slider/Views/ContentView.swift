//
//  ContentView.swift
//  KH Volume slider
//
//  Created by Leander Blume on 21.12.24.
//

import SwiftUI

struct ContentView: View {
    @State var khAccess = KHAccess()
    @State var selectedEq: Int = 0
    @State var selectedEqBand: Int = 0

    var body: some View {
        VStack {
            Text("Monitor volume")
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
            // We don't want to run this every time the window opens, only once. But how?
            .task {
                guard (try? await khAccess.checkSpeakersAvailable()) != nil else {
                    return
                }
                try? await khAccess.backupAndFetch()
            }
            
            Text("\(Int(khAccess.volume)) dB")

            Divider()
            
            HStack {
                Picker("EQ:", selection: $selectedEq) {
                    Text("eq2").tag(0)
                    Text("eq3").tag(1)
                }
                .frame(width: 150)
                .onChange(of: selectedEq) {
                    // not enough
                    selectedEqBand = 0
                }
                Picker("Band:", selection: $selectedEqBand) {
                    ForEach((1...khAccess.eqs[selectedEq].boost.count), id: \.self) { i in
                        Text("\(i)").tag(i - 1)
                    }
                }.frame(width: 120)
            }
            EqBandPanel(
                khAccess: khAccess,
                selectedEq: selectedEq,
                selectedEqBand: selectedEqBand
            
            )
            
            Divider()

            HStack {
                Button("Fetch") {
                    Task {
                        try await khAccess.backupAndFetch()
                    }
                }
                .disabled(khAccess.status == .fetching || khAccess.status == .speakersUnavailable)

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                StatusDisplay(status: khAccess.status)
            }
            
        }
        .padding()
        .frame(width: 550)
    }
}

#Preview {
    ContentView()
}

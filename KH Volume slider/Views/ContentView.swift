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
    // TODO set this somewhere
    @State var fetching: Bool = false
    @State var sendingEqSettings: Bool = false

    var body: some View {
        VStack {
            Text("Monitor volume")
            Slider(value: $khAccess.volume, in: 0...120, step: 6) {
                Text("")
            } minimumValueLabel: {
                Text("0")
            } maximumValueLabel: {
                Text("120")
            } onEditingChanged: { editing in
                if !editing {
                    Task {
                        await khAccess.sendVolumeToDevice()
                    }
                }
            }
            // We don't want to run this every time the window opens, only once. But how?
            .disabled(khAccess.speakersAvailable)
            .task {
                fetching = true
                await khAccess.backupAndFetch()
                fetching = false
            }
            
            Text("\(Int(khAccess.volume)) dB")

            Divider()
            
            Picker("EQ:", selection: $selectedEq) {
                Text("eq2").tag(0)
                Text("eq3").tag(1)
            }
            .frame(width: 150)
            .onChange(of: selectedEq) {
                // not enough
                selectedEqBand = 0
            }

            HStack {
                Picker("EQ Band:", selection: $selectedEqBand) {
                    ForEach((1...khAccess.eqs[selectedEq].boost.count), id: \.self) { i in
                        Text("\(i)").tag(i - 1)
                    }
                }.frame(width: 120)
                
                Picker("Type:", selection: $khAccess.eqs[selectedEq].type[selectedEqBand]) {
                    ForEach(Eq.EqType.allCases) { type in
                        Text(type.rawValue).tag(type.rawValue)
                    }
                }.frame(width: 160)
                
                Toggle("Enabled", isOn: $khAccess.eqs[selectedEq].enabled[selectedEqBand])
                
                Button(sendingEqSettings ? "Sending..." : "Send EQ settings") {
                    Task {
                        sendingEqSettings = true
                        await khAccess.sendEqToDevice()
                        sendingEqSettings = false
                    }
                }
                .frame(height: 20)
                .disabled(sendingEqSettings || !khAccess.speakersAvailable)
                if sendingEqSettings {
                    ProgressView().scaleEffect(0.5).frame(height: 20)
                }
            }
            Grid(alignment: .topLeading) {
                let sliders = [
                    EqSlider.SliderData(
                        binding: $khAccess.eqs[selectedEq].frequency,
                        name: "Frequency",
                        unit: "Hz",
                        range: 10...24000
                    ),
                    EqSlider.SliderData(
                        binding: $khAccess.eqs[selectedEq].boost,
                        name: "Boost",
                        unit: "dB",
                        range: -99...24
                    ),
                    EqSlider.SliderData(
                        binding: $khAccess.eqs[selectedEq].q,
                        name: "Q",
                        unit: nil,
                        range: 0.1...16
                    ),
                    EqSlider.SliderData(
                        binding: $khAccess.eqs[selectedEq].gain,
                        name: "Gain",
                        unit: "dB",
                        range: -99...24
                    )
                ]
                ForEach(sliders) { sliderdata in
                    GridRow {
                        EqSlider(
                            binding: sliderdata.binding,
                            name: sliderdata.name,
                            unit: sliderdata.unit,
                            range: sliderdata.range,
                            selectedEqBand: selectedEqBand
                        )
                    }
                }
            }

            Divider()

            HStack {
                Button(fetching ? "Fetching..." : "Fetch") {
                    Task {
                        fetching = true
                        await khAccess.backupAndFetch()
                        fetching = false
                    }
                }
                .frame(height: 20)
                .disabled(fetching || !khAccess.speakersAvailable)
                if fetching {
                    ProgressView().scaleEffect(0.5).frame(height: 20)
                }

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
            }
            
        }
        .padding()
        .frame(width: 550)
    }
}

#Preview {
    ContentView()
}

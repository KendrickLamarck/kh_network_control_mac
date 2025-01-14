//
//  EqPanel.swift
//  KH Volume slider
//
//  Created by Leander Blume on 14.01.25.
//

import SwiftUI

// NOT USED but maybe in the future
// although I don't really see it working right now.
struct EqPanel: View {
    @State var eq: Eq
    @State var sendingEqSettings: Bool
    var selectedEq: Int
    @State var selectedEqBand: Int
    
    var body: some View {
        HStack {
            Picker("EQ Band:", selection: $selectedEqBand) {
                ForEach((1...eq.boost.count), id: \.self) { i in
                    Text("\(i)").tag(i - 1)
                }
            }.frame(width: 120)
            
            Picker("Type:", selection: $eq.type[selectedEqBand]) {
                ForEach(Eq.EqType.allCases) { type in
                    Text(type.rawValue).tag(type.rawValue)
                }
            }.frame(width: 160)
            
            Toggle("Enabled", isOn: $eq.enabled[selectedEqBand])
            
            Button(sendingEqSettings ? "Sending..." : "Send EQ settings") {
                Task {
                    sendingEqSettings = true
                    await sendEqToDevice()
                    sendingEqSettings = false
                }
            }
            .frame(height: 20)
            .disabled(sendingEqSettings)
            if sendingEqSettings {
                ProgressView().scaleEffect(0.5).frame(height: 20)
            }
        }
        Grid(alignment: .topLeading) {
            let sliders: [EqSlider.SliderData] = [
                EqSlider.SliderData(
                    binding: $eq.frequency,
                    name: "Frequency",
                    unit: "Hz",
                    range: 10...24000
                ),
                EqSlider.SliderData(
                    binding: $eq.boost,
                    name: "Boost",
                    unit: "dB",
                    range: -99...24
                ),
                EqSlider.SliderData(
                    binding: $eq.q,
                    name: "Q",
                    unit: nil,
                    range: 0.1...16
                ),
                EqSlider.SliderData(
                    binding: $eq.gain,
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
    }
    
    func sendEqToDevice() async {    }
}

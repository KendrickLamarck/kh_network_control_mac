//
//  EqPanel.swift
//  KH Volume slider
//
//  Created by Leander Blume on 14.01.25.
//

import SwiftUI

struct EqSlider: View {
    var binding: Binding<[Double]>
    var name: String
    var unit: String?
    var range: ClosedRange<Double>
    var logarithmic: Bool
    var selectedEqBand: Int
    
    var body: some View {
        let unitString: String = unit != nil ? " (\(unit!))" : ""
        Text(name + unitString)
        if logarithmic {
            Slider.withLog2Scale(value: binding[selectedEqBand], in: range)
        } else {
            Slider(value: binding[selectedEqBand], in: range)
        }
        TextField(
            "Frequency",
            value: binding[selectedEqBand],
            format: .number.precision(.fractionLength(1))
        ).frame(width:80)
    }
}


struct EqBandPanel: View {
    @Bindable var khAccess: KHAccess
    var selectedEq: Int
    var selectedEqBand: Int

    var body: some View {
        HStack {
            Picker("Type:", selection: $khAccess.eqs[selectedEq].type[selectedEqBand]) {
                ForEach(Eq.EqType.allCases) { type in
                    Text(type.rawValue).tag(type.rawValue)
                }
            }.frame(width: 160)
            
            Toggle("Enabled", isOn: $khAccess.eqs[selectedEq].enabled[selectedEqBand])
            
            Button(khAccess.sendingEqSettings ? "Sending..." : "Send EQ settings") {
                Task {
                    try await khAccess.sendEqToDevice()
                }
            }
            .frame(height: 20)
            .disabled(khAccess.sendingEqSettings || !khAccess.speakersAvailable)
            if khAccess.sendingEqSettings {
                ProgressView().scaleEffect(0.5).frame(height: 20)
            }
        }
        Grid(alignment: .topLeading) {
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].frequency,
                    name: "Frequency",
                    unit: "Hz",
                    range: 10...24000,
                    logarithmic: true,
                    selectedEqBand: selectedEqBand
                )
            }
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].q,
                    name: "Q",
                    unit: nil,
                    range: 0.1...16,
                    logarithmic: true,
                    selectedEqBand: selectedEqBand
                )
            }
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].boost,
                    name: "Boost",
                    unit: "dB",
                    range: -99...24,
                    logarithmic: false,
                    selectedEqBand: selectedEqBand
                )
            }
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].gain,
                    name: "Makeup",
                    unit: "dB",
                    range: -99...24,
                    logarithmic: false,
                    selectedEqBand: selectedEqBand
                )
            }
        }
    }
}

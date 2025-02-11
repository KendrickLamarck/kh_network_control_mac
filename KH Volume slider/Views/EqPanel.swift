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
            name,
            value: binding[selectedEqBand],
            format: .number.precision(.fractionLength(1))
        ).frame(width: 80)
    }
}

struct EqBandPanel: View {
    @Bindable var khAccess: KHAccess
    var selectedEq: Int
    var selectedEqBand: Int

    var body: some View {
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
        HStack {
            Picker("Type:", selection: $khAccess.eqs[selectedEq].type[selectedEqBand]) {
                ForEach(Eq.EqType.allCases) { type in
                    Text(type.rawValue).tag(type.rawValue)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
            Spacer()
            Toggle(
                "Enable band", isOn: $khAccess.eqs[selectedEq].enabled[selectedEqBand]
            ).toggleStyle(.switch)
        }
    }
}

struct EqPanel: View {
    var khAccess: KHAccess

    @State private var selectedEq: Int = 0
    /// doesn't seem very elegant. But if I make this a single `@State: Int`, it seems
    /// to be shared between instances if this view. I don't know how to do that.
    /// OK there are ways to do it (using the `.id()` modifier), but then the state resets
    /// when switching EQs. I don't think I want that.
    @State private var selectedEqBand: [Int] = [0, 0]
    var body: some View {
        VStack(spacing: 20) {
            Picker("", selection: $selectedEq) {
                Text("eq2").tag(0)
                Text("eq3").tag(1)
            }
            .pickerStyle(.segmented)

            EqBandPanel(
                khAccess: khAccess,
                selectedEq: selectedEq,
                selectedEqBand: selectedEqBand[selectedEq]
            )

            ZStack {
                Picker("", selection: $selectedEqBand[selectedEq]) {
                    ForEach((1...10), id: \.self) { i in
                        Text("\(i)").tag(i - 1)
                    }
                }
                .pickerStyle(.segmented)
                .opacity(selectedEq == 0 ? 1 : 0)
                VStack {
                    Picker("", selection: $selectedEqBand[selectedEq]) {
                        ForEach((1...10), id: \.self) { i in
                            Text("\(i)").tag(i - 1)
                        }
                    }
                    .pickerStyle(.segmented)
                    Picker("", selection: $selectedEqBand[selectedEq]) {
                        ForEach((11...20), id: \.self) { i in
                            Text("\(i)").tag(i - 1)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .opacity(selectedEq == 1 ? 1 : 0)
            }

            Button("Send EQ") {
                Task {
                    try await khAccess.send()
                }
            }
        }
    }
}

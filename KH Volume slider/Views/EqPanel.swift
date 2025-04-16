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
    var khAccess: KHAccess

    var body: some View {
        let unitString: String = unit != nil ? " (\(unit!))" : ""

        #if os(macOS)
        Text(name + unitString)
        if logarithmic {
            Slider.withLog2Scale(value: binding[selectedEqBand], in: range) {editing in
                if !editing {
                    Task {
                        try await khAccess.send()
                    }
                }
            }
        } else {
            Slider(value: binding[selectedEqBand], in: range) {editing in
                if !editing {
                    Task {
                        try await khAccess.send()
                    }
                }
            }
        }
        TextField(
            name,
            value: binding[selectedEqBand],
            format: .number.precision(.fractionLength(1))
        )
        .frame(width: 80)
        .onSubmit {
            Task {
                try await khAccess.send()
            }
        }
        #elseif os(iOS)
        VStack {
            Text(name + unitString)

            HStack {
                if logarithmic {
                    Slider.withLog2Scale(value: binding[selectedEqBand], in: range) {
                        editing in
                        if !editing {
                            Task {
                                try await khAccess.send()
                            }
                        }
                    }
                } else {
                    Slider(value: binding[selectedEqBand], in: range) { editing in
                        if !editing {
                            Task {
                                try await khAccess.send()
                            }
                        }
                    }
                }

                TextField(
                    name,
                    value: binding[selectedEqBand],
                    format: .number.precision(.fractionLength(1))
                )
                .frame(width: 80)
                .onSubmit {
                    Task {
                        try await khAccess.send()
                    }
                }
            }
        }
        #endif
    }
}

struct EqBandPanel: View {
    @Bindable var khAccess: KHAccess
    var selectedEq: Int
    var selectedEqBand: Int

    var body: some View {
        #if os(macOS)
        Grid(alignment: .topLeading) {
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].frequency,
                    name: "Frequency",
                    unit: "Hz",
                    range: 10...24000,
                    logarithmic: true,
                    selectedEqBand: selectedEqBand,
                    khAccess: khAccess
                )
            }
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].q,
                    name: "Q",
                    unit: nil,
                    range: 0.1...16,
                    logarithmic: true,
                    selectedEqBand: selectedEqBand,
                    khAccess: khAccess
                )
            }
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].boost,
                    name: "Boost",
                    unit: "dB",
                    range: -99...24,
                    logarithmic: false,
                    selectedEqBand: selectedEqBand,
                    khAccess: khAccess
                )
            }
            GridRow {
                EqSlider(
                    binding: $khAccess.eqs[selectedEq].gain,
                    name: "Makeup",
                    unit: "dB",
                    range: -99...24,
                    logarithmic: false,
                    selectedEqBand: selectedEqBand,
                    khAccess: khAccess
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
            .onChange(of: khAccess.eqs[selectedEq].type) {
                Task {
                    // This happens when eq is switched. Should not happen.
                    print("ZXCV")
                    try await khAccess.send()
                }
            }
            .disabled(khAccess.eqs[selectedEq].enabled[selectedEqBand])
            if khAccess.eqs[selectedEq].enabled[selectedEqBand] {
                Text("Disable to change type")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle(
                "Enable band", isOn: $khAccess.eqs[selectedEq].enabled[selectedEqBand]
            )
            .toggleStyle(.switch)
            .onChange(of: khAccess.eqs[selectedEq].enabled) {
                Task {
                    // This is triggered when eq is switched. Should not happen.
                    print("QWER")
                    try await khAccess.send()
                }
            }
        }
        #elseif os(iOS)
        VStack {
            EqSlider(
                binding: $khAccess.eqs[selectedEq].frequency,
                name: "Frequency",
                unit: "Hz",
                range: 10...24000,
                logarithmic: true,
                selectedEqBand: selectedEqBand,
                khAccess: khAccess
            )
            EqSlider(
                binding: $khAccess.eqs[selectedEq].q,
                name: "Q",
                unit: nil,
                range: 0.1...16,
                logarithmic: true,
                selectedEqBand: selectedEqBand,
                khAccess: khAccess
            )
            EqSlider(
                binding: $khAccess.eqs[selectedEq].boost,
                name: "Boost",
                unit: "dB",
                range: -99...24,
                logarithmic: false,
                selectedEqBand: selectedEqBand,
                khAccess: khAccess
            )
            EqSlider(
                binding: $khAccess.eqs[selectedEq].gain,
                name: "Makeup",
                unit: "dB",
                range: -99...24,
                logarithmic: false,
                selectedEqBand: selectedEqBand,
                khAccess: khAccess
            )
        }
        VStack {
            Picker("Type:", selection: $khAccess.eqs[selectedEq].type[selectedEqBand]) {
                ForEach(Eq.EqType.allCases) { type in
                    Text(type.rawValue).tag(type.rawValue)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 160)
            .onChange(of: khAccess.eqs[selectedEq].type) {
                Task {
                    try await khAccess.send()
                }
            }
            .disabled(khAccess.eqs[selectedEq].enabled[selectedEqBand])

            if khAccess.eqs[selectedEq].enabled[selectedEqBand] {
                Text("Disable to change type")
                    .foregroundStyle(.secondary)
            }

            Toggle(
                "Enable band",
                isOn: $khAccess.eqs[selectedEq].enabled[selectedEqBand]
            )
            .toggleStyle(.switch)
            .onChange(of: khAccess.eqs[selectedEq].enabled) {
                Task {
                    try await khAccess.send()
                }
            }

        }
        #endif
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
            
            #if os(macOS)
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
            #elseif os(iOS)
            ZStack {
                Picker(selection: $selectedEqBand[selectedEq], label: Text("EQ Band")) {
                    ForEach((1...10), id: \.self) { i in
                        Text("\(i)").tag(i - 1)
                    }
                }
                .opacity(selectedEq == 0 ? 1 : 0)
                Picker(
                    selection: $selectedEqBand[selectedEq],
                    label: Text("EQ Band")
                ) {
                    ForEach((1...20), id: \.self) { i in
                        Text("\(i)").tag(i - 1)
                    }
                }
                .opacity(selectedEq == 1 ? 1 : 0)
            }
            .pickerStyle(.wheel)
            #endif
        }
        .scenePadding()
    }
}

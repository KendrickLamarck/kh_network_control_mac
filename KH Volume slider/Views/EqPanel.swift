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
                    try await khAccess.send()
                }
            }
            .disabled(khAccess.eqs[selectedEq].enabled[selectedEqBand])
            
            Text("Disable to change type")
                .opacity(khAccess.eqs[selectedEq].enabled[selectedEqBand] ? 1 : 0)

            Spacer()

            Toggle(
                "Enable band", isOn: $khAccess.eqs[selectedEq].enabled[selectedEqBand]
            )
            .toggleStyle(.switch)
            .onChange(of: khAccess.eqs[selectedEq].enabled) {
                Task {
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
            
            Text("Disable to change type")
                .opacity(khAccess.eqs[selectedEq].enabled[selectedEqBand] ? 1 : 0)
            
            Spacer()

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

struct EqPanel_: View {
    var khAccess: KHAccess
    var selectedEq: Int
    @State private var selectedEqBand: Int = 0
    
    var body: some View {
        var numBands: Int {
            khAccess.eqs[selectedEq].enabled.count
        }

        VStack {
            EqBandPanel(
                khAccess: khAccess,
                selectedEq: selectedEq,
                selectedEqBand: selectedEqBand
            )
            
            Spacer()

            #if os(macOS)
            VStack {
                ForEach((1...numBands/10), id: \.self) { row in
                    Picker("", selection: $selectedEqBand) {
                        ForEach((10 * (row - 1) ... 10 * row - 1), id: \.self) { i in
                            Text("\(i+1)").tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
            #elseif os(iOS)
            Picker(selection: $selectedEqBand, label: Text("EQ Band")) {
                ForEach((1...numBands), id: \.self) { i in
                    Text("\(i)").tag(i - 1)
                }
            }
            .pickerStyle(.wheel)
            #endif
        }
    }
}

struct EqPanel: View {
    var khAccess: KHAccess

    @State private var selectedEq: Int = 0
    var body: some View {
        VStack(spacing: 20) {
            Picker("", selection: $selectedEq) {
                Text("post EQ").tag(0)
                Text("calibration EQ").tag(1)
            }
            .pickerStyle(.segmented)
                        
            ZStack {
                EqPanel_(khAccess: khAccess, selectedEq: 0)
                    .opacity(selectedEq == 0 ? 1 : 0)
                EqPanel_(khAccess: khAccess, selectedEq: 1)
                    .opacity(selectedEq == 1 ? 1 : 0)
            }
        }
    }
}

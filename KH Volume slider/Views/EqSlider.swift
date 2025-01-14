//
//  EqSlider.swift
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

    @State var eqs: [Eq]
    @State var selectedEq: Int = 0
    @State var selectedEqBand: Int = 0
    
    internal struct SliderData: Identifiable {
        let binding: Binding<[Double]>
        let name: String
        let unit: String?
        let range: ClosedRange<Double>

        var id: String { name }
    }
    
    var body: some View {
        let unitString: String = unit != nil ? " (\(unit!))" : ""
        Text(name + unitString)
        Slider(value: binding[selectedEqBand], in: range)
        TextField(
            "Frequency",
            value: binding[selectedEqBand],
            format: .number.precision(.fractionLength(1))
        ).frame(width:80)
    }
}

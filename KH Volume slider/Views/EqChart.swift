//
//  EqChart.swift
//  KH Volume slider
//
//  Created by Leander Blume on 23.06.25.
//

import SwiftUI
import Charts

struct EqChart: View {
    var khAccess: KHAccess

    var body: some View {
        let eqs = khAccess.eqs

        Chart {
            LinePlot(x: "f", y: "Gain") { f in
                var result = 0.0
                // We should loop over bands before looping over frequencies
                for selectedEq in 0 ... 1 {
                    let eq = eqs[selectedEq]
                    for band in 0 ..< eq.type.count {
                        guard eq.enabled[band] else {
                            continue
                        }
                        guard eq.type[band] == Eq.EqType.parametric.rawValue else {
                            print("EQ type not supported yet")
                            continue
                        }
                        print("calculating band \(band + 1)...")
                        let boost = eq.boost[band]
                        let gain = eq.gain[band]
                        let q = eq.q[band]
                        let f0 = eq.frequency[band]
                        let bandResult = boost * 1 / (1 + pow(q * (f / f0 - f0 / f), 2))
                        result += bandResult + gain
                    }
                }
                return result
            }
        }
        .chartXScale(domain: 20 ... 20000, type: .log)
        .chartYScale(domain: -24 ... 24)
    }
}

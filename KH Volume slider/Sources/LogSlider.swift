//
//  LogSlider.swift
//  KH Volume slider
//
//  Created by Leander Blume on 16.01.25.
//

import SwiftUI

extension Binding where Value == Double {
    /// Returns a new version of the binding that scales the value logarithmically using the specified base. That is,
    /// when getting the value, `log_b(value)` is returned; when setting it, the new value is `pow(base, newValue)`.
    ///
    /// - Parameter base: The base to use.
    func logarithmic(base: Double = 2) -> Binding<Double> {
        Binding(
            get: {
                log10(self.wrappedValue) / log10(base)
            },
            set: { (newValue) in
                self.wrappedValue = pow(base, newValue)
            }
        )
    }
}


extension Slider where Label == EmptyView, ValueLabel == EmptyView {
    /// Creates a new `Slider` with a base-10 logarithmic scale.
    ///
    /// ## Example
    ///
    ///     @State private var frequency = 1.0
    ///
    ///     var body: some View {
    ///         Slider.withLog10Scale(value: $frequency, in: 1 ... 100)
    ///     }
    ///
    /// - Parameters:
    ///   - value: A binding to the unscaled value.
    ///   - range: The unscaled range of values.
    ///   - onEditingChanged: Documentation forthcoming.
    static func withLog2Scale(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        onEditingChanged: @escaping (Bool) -> Void = { _ in }
    ) -> Slider {
        return self.init(
            value: value.logarithmic(),
            in: log2(range.lowerBound) ... log2(range.upperBound),
            onEditingChanged: onEditingChanged
        )
    }
}

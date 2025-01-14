//
//  KHJSON.swift
//  KH Volume slider
//
//  Created by Leander Blume on 14.01.25.
//

import SwiftUI

struct Eq: Codable {
    var boost: [Double]
    var enabled: [Bool]
    var frequency: [Double]
    var gain: [Double]
    var q: [Double]
    var type: [String]

    enum EqType: String, CaseIterable, Identifiable {
        case parametric = "PARAMETRIC"
        case loshelf = "LOSHELF"
        case hishelf = "HISHELF"
        case lowpass = "LOWPASS"
        case highpass = "HIGHPASS"
        case bandpass = "BANDPASS"
        case notch = "NOTCH"
        case allpass = "ALLPASS"
        case hi6db = "HI6DB"
        case lo6db = "LO6DB"
        case inversion = "INVERSION"

        var id: String { self.rawValue }
    }
}

struct KHJSON: Codable {
    var devices: [String: Device]
 
    struct Device: Codable {
        var product: String
        var serial: String
        var version: String
        var commands: Commands
        
        struct Commands: Codable {
            var audio: Audio
            
            struct Audio: Codable {
                var out: Outparams

                struct Outparams: Codable {
                    var level: Double?
                    var eq2: Eq
                    var eq3: Eq
                }
            }
        }
    }

    func writeToFile(filePath: URL) throws {
        try JSONEncoder().encode(self).write(to: filePath)
    }
}

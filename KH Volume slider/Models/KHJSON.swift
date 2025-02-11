//
//  KHJSON.swift
//  KH Volume slider
//
//  Created by Leander Blume on 14.01.25.
//

import SwiftUI

struct Eq: Codable, Equatable {
    var boost: [Double]
    var enabled: [Bool]
    var frequency: [Double]
    var gain: [Double]
    var q: [Double]
    var type: [String]

    init(numBands: Int) {
        boost = Array(repeating: 0.0, count: numBands)
        enabled = Array(repeating: false, count: numBands)
        frequency = Array(repeating: 100.0, count: numBands)
        gain = Array(repeating: 0.0, count: numBands)
        q = Array(repeating: 0.7, count: numBands)
        type = Array(repeating: Eq.EqType.parametric.rawValue, count: numBands)
    }

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

struct Commands: Codable {
    var audio: Audio
    
    struct Audio: Codable {
        var out: Outparams
        
        struct Outparams: Codable {
            var level: Double
            var mute: Bool
            var solo: Bool
            var eq2: Eq
            var eq3: Eq
            var delay: Double
            var phaseinversion: Bool
            var mixer: Mixer

            struct Mixer: Codable {
                var inputs: [String]
                var levels: [Double]
            }
        }
    }
    
    var ui: UI
    
    struct UI: Codable {
        var logo: Logo
        
        struct Logo: Codable {
            var brightness: Double
        }
    }
}

struct KHJSON: Codable {
    /*
     struct mirroring the structure of backup.json created by khtool.
     */
    var devices: [String: Device]
 
    struct Device: Codable {
        var product: String
        var serial: String
        var version: String
        var commands: Commands
    }

    func writeToFile(filePath: URL) throws {
        try JSONEncoder().encode(self).write(to: filePath)
    }
}

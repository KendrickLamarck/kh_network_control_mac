//
//  KH_Volume_sliderTests.swift
//  KH Volume sliderTests
//
//  Created by Leander Blume on 21.12.24.
//

import Foundation
import Testing
@testable import KH_Volume_slider

struct KH_Volume_sliderTests_Online {

    @Test func testSendToDevice() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let khAccess = KHAccess()
        try await khAccess.backupAndFetch()
        try await khAccess.send()
    }
}

struct KH_Volume_sliderTests_Offline {

    @Test func testReadFromBackup() async throws {
        #expect(true)
    }
}


struct SSCTest {
    @Test func testSSCDevice() throws {
        let TX = "{\"audio\":{\"out\":{\"mute\":false}}}"
        let ip = "2003:c1:df03:a100:2a36:38ff:fe61:7506"
        let sscDevice = try SSCDevice(ip: ip)
        #expect(sscDevice.transaction.TX == "")
        #expect(sscDevice.transaction.RX == "")
        sscDevice.connect()
        
        sscDevice.sendMessage(TX)
        sleep(1)
        #expect(sscDevice.transaction.TX == TX)
        #expect(sscDevice.transaction.RX == "")
        
        sscDevice.receiveMessage()
        sleep(1)
        #expect(sscDevice.transaction.TX == TX)
        #expect(sscDevice.transaction.RX.starts(with: TX))
    }
}

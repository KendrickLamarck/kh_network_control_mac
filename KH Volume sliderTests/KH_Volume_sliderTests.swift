//
//  KH_Volume_sliderTests.swift
//  KH Volume sliderTests
//
//  Created by Leander Blume on 21.12.24.
//

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
    @Test func testSendMessage() throws {
        let TX = "{\"audio\":{\"out\":{\"mute\":false}}}"
        try sendSSCMessage(TX)
    }
    
    @Test func testSSCDevice() {
        let TX = "{\"audio\":{\"out\":{\"mute\":false}}}"
        let ip = "2003:c1:df03:a100:2a36:38ff:fe61:7506"
        let sscDevice = SSCDevice(ip: ip)
        sscDevice.connect()
        sscDevice.sendMessage(TX)
        sscDevice.receiveMessage()
    }
}

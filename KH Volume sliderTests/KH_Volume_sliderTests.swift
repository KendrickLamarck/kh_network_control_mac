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
    @Test func testSendMessage() {
        let ip = "2003:c1:df03:a100:2a36:38ff:fe61:7506"
        guard let sscDevice = SSCDevice(ip: ip) else {
            #expect(Bool(false))
            return
        }
        sscDevice.connect()
        
        let TX1 = "{\"audio\":{\"out\":{\"mute\":true}}}"
        let t1 = sscDevice.sendMessage(TX1)
        sleep(1)
        #expect(t1.TX == TX1)
        #expect(t1.RX.starts(with: TX1))
        
        let TX2 = "{\"audio\":{\"out\":{\"mute\":false}}}"
        let t2 = sscDevice.sendMessage(TX2)
        sleep(1)
        #expect(t2.TX == TX2)
        #expect(t2.RX.starts(with: TX2))
    }
    
    @Test func testSendMessageWithScan() {
        let endpoint = SSCDevice.scan()[0]
        let sscDevice = SSCDevice(endpoint: endpoint)
        sscDevice.connect()
        
        let TX1 = "{\"audio\":{\"out\":{\"mute\":true}}}"
        let t1 = sscDevice.sendMessage(TX1)
        sleep(1)
        #expect(t1.TX == TX1)
        #expect(t1.RX.starts(with: TX1))
        
        let TX2 = "{\"audio\":{\"out\":{\"mute\":false}}}"
        let t2 = sscDevice.sendMessage(TX2)
        sleep(1)
        #expect(t2.TX == TX2)
        #expect(t2.RX.starts(with: TX2))
    }
    
    @Test func testScan() {
        print(SSCDevice.scan())
    }
}

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

//
//  KH_Volume_sliderTests.swift
//  KH Volume sliderTests
//
//  Created by Leander Blume on 21.12.24.
//

import Testing
@testable import KH_Volume_slider

struct KH_Volume_sliderTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

    @Test func testVolume() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let app = await ContentView()
        await app.sendVolumeToDevice()
        await app.readVolumeFromBackup()
    }

    @Test func testPythonReachable() async throws {
        let app = await ContentView()
        #expect(await app.runKHToolProcess(args: ["-v"]) == 0)
    }
}

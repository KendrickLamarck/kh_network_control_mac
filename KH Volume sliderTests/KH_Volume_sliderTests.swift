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
        let app = await KH_Volume_slider.ContentView()
        await app.sendVolume(volume: 23)
        await #expect(app.volume == 23.0)
        await app.setVolume(volume: 55)
        await app.readVolumeFromBackup()
        await #expect(app.volume == 55.0)
    }

}

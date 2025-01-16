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
        let khAccess = KHAccess()
        await khAccess.sendVolumeToDevice()
        khAccess.readVolumeFromBackup()
    }
    
    @Test func testReadFromBackup() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        let khAccess = KHAccess()
        khAccess.readVolumeFromBackup()
        #expect(khAccess.volume == 54)
        khAccess.readEqFromBackup()
        #expect(khAccess.eqs[1].frequency[0] == 43)
    }


    @Test func testPythonReachable() async throws {
        let khAccess = KHAccess()
        let exitCode = await khAccess._runKHToolProcess(args: ["-v"])
        #expect(exitCode == 0)
    }
}

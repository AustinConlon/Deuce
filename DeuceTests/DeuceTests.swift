//
//  DeuceTests.swift
//  DeuceTests
//
//  Created by Austin Conlon on 8/13/18.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import XCTest
@testable import Deuce

class DeuceTests: XCTestCase {
    func testStatisticsPositive() {
        for _ in 0...100 {
            let match = Match.random()
            XCTAssert(match.playerOneServicePointsWon >= 0)
            XCTAssert(match.playerTwoServicePointsWon >= 0)
            XCTAssert(match.playerOneReturnPointsWon >= 0)
            XCTAssert(match.playerTwoReturnPointsWon >= 0)
        }
    }
}

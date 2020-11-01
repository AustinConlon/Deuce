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
        }
    }
    
    func testPointCount() {
        let match = Match.random()
        let playerOnePointsPlayed = match.playerOneServicePointsPlayed + match.playerTwoServicePointsPlayed
        let playerTwoPointsPlayed = match.playerTwoServicePointsPlayed + match.playerOneServicePointsPlayed
        XCTAssertEqual(playerOnePointsPlayed, match.allPointsPlayed.count)
        XCTAssertEqual(playerTwoPointsPlayed, match.allPointsPlayed.count)
    }
}

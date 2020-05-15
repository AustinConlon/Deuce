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
    func test() {
        let match = Match.random()
        for _ in match.setsWon {
            print()
        }
        print(match.setsWon)
    }
}

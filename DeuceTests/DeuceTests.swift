//
//  DeuceTests.swift
//  DeuceTests
//
//  Created by Austin Conlon on 8/13/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import XCTest
@testable import Deuce

class DeuceTests: XCTestCase {
    func testPlayerOneWonGame() {
        let match = MatchManager(1, .tiebreak, .one)
        match.sets.last?.games.last?.playerOneScore = 40
        match.scorePointForPlayerOne()
        XCTAssertEqual(match.sets.last!.playerOneSetScore, 1)
    }
    
    func testPlayerTwoWonGame() {
        let match = MatchManager(1, .tiebreak, .one)
        match.sets.last?.games.last?.playerTwoScore = 40
        match.scorePointForPlayerTwo()
        XCTAssertEqual(match.sets.last!.playerTwoSetScore, 1)
    }
    
    func testPlayerOneWonSet() {
        let match = MatchManager(3, .tiebreak, .one)
        match.sets.last?.playerOneSetScore = 5
        match.sets.last?.games.last?.playerOneScore = 40
        match.scorePointForPlayerOne()
        XCTAssertEqual(match.sets.last?.playerOneSetScore, match.sets.last?.playerTwoSetScore)
        XCTAssertEqual(match.playerOneMatchScore, 1)
    }
    
    func testPlayerTwoWonSet() {
        let match = MatchManager(3, .tiebreak, .one)
        match.sets.last?.playerTwoSetScore = 5
        match.sets.last?.games.last?.playerTwoScore = 40
        match.scorePointForPlayerTwo()
        XCTAssertEqual(match.sets.last?.playerOneSetScore, match.sets.last?.playerTwoSetScore)
        XCTAssertEqual(match.playerTwoMatchScore, 1)
    }
    
    func testPlayerOneWonMatch() {
        let match = MatchManager(1, .tiebreak, .one)
        match.sets.last?.playerOneSetScore = 5
        match.sets.last?.games.last?.playerOneScore = 40
        match.scorePointForPlayerOne()
        XCTAssertEqual(match.winner, Player.one)
    }
    
    func testPlayerTwoWonMatch() {
        let match = MatchManager(1, .tiebreak, .one)
        match.sets.last?.playerTwoSetScore = 5
        match.sets.last?.games.last?.playerTwoScore = 40
        match.scorePointForPlayerTwo()
        XCTAssertEqual(match.winner, Player.two)
    }
}

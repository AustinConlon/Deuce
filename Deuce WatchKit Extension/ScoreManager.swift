//
//  ScoreManager.swift
//  Deuce
//
//  Created by Austin Conlon on 4/22/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity

let playerOne = ScoreManager(player: .first)
let playerTwo = ScoreManager(player: .second)

class ScoreManager {
    
    // MARK: Properties
    enum SetType {
        case tiebreak, advantage
    }
    
    enum Player {
        case first, second
    }
    
    enum ServingSide {
        case left, right
    }
    
    static var matchLength = 1
    static var setType = SetType.advantage
    static var server: Player = determineWhoServes() {
        didSet {
            switch server { // Server always starts on the right side of the court from their perspective
            case .first:
                playerOne.servingSide = .left
                playerTwo.servingSide = nil
            case .second:
                playerOne.servingSide = nil
                playerTwo.servingSide = .right
            }
        }
    }
    var servingSide: ServingSide? // Start on right side at the beginning of each game
    static var isDeuce = false
    static var isInTiebreakGame = false
    static var advantage: Player?
    
    
    static var winner: Player? 
    
    var playerThatScored: Player // For determining whether the first player or the second player object is calling the scoring method
    var gameScore = 0 {
        didSet {
            updateServingSideOfServer()
        }
    }
    var gamesWon = 0 {
        didSet {
            ScoreManager.resetGameScores()
            ScoreManager.switchServer()
        }
    }
    var setsWon = 0
    
    // MARK: Initialization
    init(player: Player) {
        self.playerThatScored = player
        switch player {
        case .first:
            servingSide = .left
        case .second:
            servingSide = .right
        }
    }
    
    // MARK: ScoreManager
    class func determineWhoServes() -> Player {
        if ((arc4random_uniform(2)) == 0) {
            return .first
        } else {
            return .second
        }
    }
    
    func updateServingSideOfServer() {
        switch ScoreManager.server {
        case .first:
            if (playerOne.gameScore, playerTwo.gameScore) == (0, 0) {
                playerOne.servingSide = .left
            } else {
                switch playerOne.servingSide {
                case .left?:
                    playerOne.servingSide = .right
                case .right?:
                    playerOne.servingSide = .left
                case .none:
                    break
                }
            }
        case .second:
            if (playerOne.gameScore, playerTwo.gameScore) == (0, 0) {
                playerTwo.servingSide = .right
            } else {
                switch playerTwo.servingSide {
                case .left?:
                    playerTwo.servingSide = .right
                case .right?:
                    playerTwo.servingSide = .left
                case .none:
                    break
                }
            }
        }
    }
    
    class func switchServer() {
        switch ScoreManager.server {
        case .first:
            ScoreManager.server = .second
        case .second:
            ScoreManager.server = .first
        }
        playerOne.servingSide = .left
        playerTwo.servingSide = .right
    }
    
    func scorePoint() {
        switch (playerThatScored, playerOne.gameScore, playerTwo.gameScore) {
        case (.first, 0...15, 0...40):
            gameScore += 15
        case (.second, 0...40, 0...15):
            gameScore += 15
        case (.first, 30, 0...40):
            gameScore += 10
            if (playerOne.gameScore == 40 && playerTwo.gameScore == 40) {
                ScoreManager.isDeuce = true
            }
        case (.second, 0...40, 30):
            gameScore += 10
            if (playerOne.gameScore == 40 && playerTwo.gameScore == 40) {
                ScoreManager.isDeuce = true
            }
        case (.first, 40, 0...30):
            playerOne.wonGame()
        case (.second, 0...30, 40):
            playerTwo.wonGame()
        default:
            scoreAdvantageSituation()
        }
    }
    
    func scoreAdvantageSituation() {
        switch ScoreManager.advantage {
        case .first?:
            switch playerThatScored {
            case .first:
                playerOne.wonGame()
            case .second:
                playerTwo.gameScore += 1
                ScoreManager.advantage = nil
                ScoreManager.isDeuce = true
            }
        case .second?:
            switch playerThatScored {
            case .first:
                playerOne.gameScore += 1
                ScoreManager.advantage = nil
                ScoreManager.isDeuce = true
            case .second:
                playerTwo.wonGame()
            }
        default:
            switch playerThatScored {
            case .first:
                playerOne.gameScore += 1
            case .second:
                playerTwo.gameScore += 1
            }
            ScoreManager.advantage = playerThatScored
            ScoreManager.isDeuce = false
        }
    }
    
    func wonGame() {
        ScoreManager.switchServer()
        ScoreManager.advantage = nil
        incrementSetScore()
    }
    
    func incrementSetScore() {
        switch (playerOne.gamesWon, playerTwo.gamesWon) {
        case (0...4, 0...4):
            gamesWon += 1
        case (5, 0...4):
            switch playerThatScored {
            case .first:
                wonSet()
            case .second:
                gamesWon += 1
            }
        case (0...4, 5):
            switch playerThatScored {
            case .first:
                gamesWon += 1
            case .second:
                wonSet()
            }
        case (5, 5):
            gamesWon += 1
        case (6, 5):
            switch playerThatScored {
            case .first:
                wonSet()
            case .second:
                gamesWon += 1
                if ScoreManager.setType == .tiebreak {
                    ScoreManager.isInTiebreakGame = true
                }
            }
        case (5, 6):
            switch playerThatScored {
            case .first:
                gamesWon += 1
                if ScoreManager.setType == .tiebreak {
                    ScoreManager.isInTiebreakGame = true
                }
            case .second:
                wonSet()
            }
        case (6, 6):
            if ScoreManager.setType == .tiebreak {
                wonSet()
                ScoreManager.isInTiebreakGame = false
            } else {
                gamesWon += 1
            }
        default: // Advantage set
            switch playerThatScored {
            case .first:
                if playerOne.gamesWon == (playerTwo.gamesWon + 1)  {
                    wonSet()
                } else {
                    gamesWon += 1
                }
            case .second:
                if playerTwo.gamesWon == (playerOne.gamesWon + 1) {
                    wonSet()
                } else {
                    gamesWon += 1
                }
            }
        }
    }
    
    func wonSet() {
        resetSetScore()
        incrementMatchScore()
    }
    
    func resetSetScore() {
        playerOne.gamesWon = 0
        playerTwo.gamesWon = 0
    }
    
    func incrementMatchScore() {
        setsWon += 1
        switch ScoreManager.matchLength {
        case 3:
            if setsWon == 2 {
                wonMatch()
            }
        case 5:
            if setsWon == 3 {
                wonMatch()
            }
        case 7:
            if setsWon == 4 {
                wonMatch()
            }
        default:
            wonMatch()
        }
    }
    
    func wonMatch() {
        ScoreManager.winner = playerThatScored
    }
    
    class func reset() {
        winner = nil
        resetGameScores()
        resetSetScores()
        resetMatchScores()
    }
    
    class func resetGameScores() {
        advantage = nil
        playerOne.gameScore = 0
        playerTwo.gameScore = 0
    }
    
    class func resetSetScores() {
        playerOne.gamesWon = 0
        playerTwo.gamesWon = 0
    }
    
    class func resetMatchScores() {
        playerOne.setsWon = 0
        playerTwo.setsWon = 0
    }
}

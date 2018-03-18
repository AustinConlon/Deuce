//
//  ScoreManager.swift
//  Deuce
//
//  Created by Austin Conlon on 3/25/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import Foundation

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
    
    static var matchLength = 1
    static var setType = SetType.advantage
    static var server: Player?
    static var isDeuce = false
    static var isInTiebreakGame = false
    static var advantage: Player?
    static var winner: Player?
    var playerThatScored: Player // For determining whether the first player or the second player object is calling the scoring method
    var gameScore = 0
    var setScore = 0
    var matchScore = 0
    
    // MARK: Initialization
    init(player: Player) {
        self.playerThatScored = player
    }

    
    // MARK: ScoreManager
    class func determineWhoServes() {
        if ((arc4random_uniform(2)) == 0) {
            ScoreManager.server = .first
        } else {
            ScoreManager.server = .second
        }
    }
    
    class func switchServer() {
        switch ScoreManager.server {
        case .first?:
            ScoreManager.server = .second
        case .second?:
            ScoreManager.server = .first
        default:
            break
        }
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
                ScoreManager.advantage = nil
                ScoreManager.isDeuce = true
            }
        case .second?:
            switch playerThatScored {
            case .first:
                ScoreManager.advantage = nil
                ScoreManager.isDeuce = true
            case .second:
                playerTwo.wonGame()
            }
        default:
            ScoreManager.advantage = playerThatScored
            ScoreManager.isDeuce = false
        }
    }
    
    func wonGame() {
        ScoreManager.switchServer()
        playerOne.gameScore = 0
        playerTwo.gameScore = 0
        ScoreManager.advantage = nil
        incrementSetScore()
    }
    
    func incrementSetScore() {
        switch (playerOne.setScore, playerTwo.setScore) {
        case (0...4, 0...4):
            setScore += 1
        case (5, 0...4):
            switch playerThatScored {
            case .first:
                wonSet()
            case .second:
                setScore += 1
            }
        case (0...4, 5):
            switch playerThatScored {
            case .first:
                setScore += 1
            case .second:
                wonSet()
            }
        case (5, 5):
            setScore += 1
        case (6, 5):
            switch playerThatScored {
            case .first:
                wonSet()
            case .second:
                if ScoreManager.setType == .tiebreak {
                    ScoreManager.isInTiebreakGame = true
                }
                setScore += 1
            }
        case (5, 6):
            switch playerThatScored {
            case .first:
                if ScoreManager.setType == .tiebreak {
                    ScoreManager.isInTiebreakGame = true
                }
                setScore += 1
            case .second:
                wonSet()
            }
        case (6, 6):
            if ScoreManager.setType == .tiebreak {
                ScoreManager.isInTiebreakGame = false
                wonSet()
            } else {
                setScore += 1
            }
        default: // Advantage set
            switch playerThatScored {
            case .first:
                if playerOne.setScore == (playerTwo.setScore + 1)  {
                    wonSet()
                } else {
                    setScore += 1
                }
            case .second:
                if playerTwo.setScore == (playerOne.setScore + 1) {
                    wonSet()
                } else {
                    setScore += 1
                }
            }
        }
    }
    
    func wonSet() {
        resetSetScore()
        incrementMatchScore()
    }
    
    func resetSetScore() {
        playerOne.setScore = 0
        playerTwo.setScore = 0
    }
    
    func incrementMatchScore() {
        matchScore += 1
        switch ScoreManager.matchLength {
        case 3:
            if matchScore == 2 {
                wonMatch()
            }
        case 5:
            if matchScore == 3 {
                wonMatch()
            }
        case 7:
            if matchScore == 4 {
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
        playerOne.setScore = 0
        playerTwo.setScore = 0
    }
    
    class func resetMatchScores() {
        playerOne.matchScore = 0
        playerTwo.matchScore = 0
    }
}

//
//  GameManager.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/30/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation

class GameManager {
    var serverSide: ServingSide = .deuceCourt
    
    var server: Player? {
        didSet {
            switch isTiebreak {
            case true:
                serverSide = .adCourt
            case false:
                serverSide = .deuceCourt
            }
        }
    }
    
    // For conveniently switching on the game score.
    var score: (Int, Int) {
        get {
           return (serverScore, receiverScore)
        }
    }
    
    var playerOneScore = 0 {
        didSet {
            oldPlayerOneScore = oldValue
            switch isTiebreak {
            case true:
                if playerOneScore > oldValue {
                    if (playerOneScore + playerTwoScore) % 2 == 0 {
                        changeServerSide()
                    } else { // Undo.
                        changeServer()
                    }
                }
            case false:
                changeServerSide()
            }
        }
    }
    
    var playerTwoScore = 0 {
        didSet {
            oldPlayerTwoScore = oldValue
            switch isTiebreak {
            case true:
                if playerTwoScore > oldValue {
                    if (playerOneScore + playerTwoScore) % 2 == 0 {
                        changeServerSide()
                    } else { // Undo.
                        changeServer()
                    }
                }
            case false:
                changeServerSide()
            }
        }
    }
    
    var serverScore: Int {
        get {
            if server == .one {
                return playerOneScore
            } else {
                return playerTwoScore
            }
        }
    }
    
    var receiverScore: Int {
        get {
            if server == .one {
                return playerTwoScore
            } else {
                return playerOneScore
            }
        }
    }
    
    var isTiebreak = false
    var isFinished = false
    
    var oldPlayerOneScore: Int?
    var oldPlayerTwoScore: Int?
    
    func changeServer() {
        switch server {
        case .one?:
            server = .two
        case .two?:
            server = .one
        default:
            break
        }
    }
    
    func changeServerSide() {
        switch serverSide {
        case .deuceCourt:
            serverSide = .adCourt
        case .adCourt:
            serverSide = .deuceCourt
        }
    }
    
    func increasePointForPlayerOne() {
        switch server {
        case .one?:
            switch score {
            case (0...15, 0...40):
                playerOneScore += 15
            case (30, 0...40):
                playerOneScore += 10
            case (40, 0...30):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationForPlayerOne()
            }
        case .two?:
            switch score {
            case (0...40, 0...15):
                playerOneScore += 15
            case (0...40, 30):
                playerOneScore += 10
            case (0...30, 40):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationForPlayerOne()
            }
        case .none:
            break
        }
    }
    
    func increasePointForPlayerTwo() {
        switch server {
        case .one?:
            switch score {
            case (0...40, 0...15):
                playerTwoScore += 15
            case (0...40, 30):
                playerTwoScore += 10
            case (0...30, 40):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationForPlayerTwo()
            }
        case .two?:
            switch score {
            case (0...15, 0...40):
                playerTwoScore += 15
            case (30, 0...40):
                playerTwoScore += 10
            case (40, 0...30):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationForPlayerTwo()
            }
        case .none:
            break
        }
    }
    
    func increaseTiebreakPointForPlayerOne() {
        playerOneScore += 1
        if (playerOneScore >= 7) && (playerOneScore >= playerTwoScore + 2) {
            scoreWinningPoint()
        }
    }
    
    func increaseTiebreakPointForPlayerTwo() {
        playerTwoScore += 1
        if (playerTwoScore >= 7) && (playerTwoScore >= playerOneScore + 2) {
            scoreWinningPoint()
        }
    }
    
    func enterDeuceOrAdvantageSituationForPlayerOne() {
        if playerOneScore == playerTwoScore + 10 {
            playerOneScore += 10
        } else if playerOneScore == playerTwoScore - 1 {
            playerOneScore += 1
        } else if playerOneScore == playerTwoScore {
            playerOneScore += 1
        } else if playerOneScore == playerTwoScore + 1 {
            scoreWinningPoint()
        }
    }
    
    func enterDeuceOrAdvantageSituationForPlayerTwo() {
        if playerTwoScore == playerOneScore + 10 {
            playerTwoScore += 10
        } else if playerTwoScore == playerOneScore - 1 {
            playerTwoScore += 1
        } else if playerTwoScore == playerOneScore {
            playerTwoScore += 1
        } else if playerTwoScore == playerOneScore + 1 {
            scoreWinningPoint()
        }
    }
    
    func scoreWinningPoint() {
        isFinished = true
    }
}

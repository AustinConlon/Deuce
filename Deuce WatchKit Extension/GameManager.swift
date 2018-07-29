//
//  GameManager.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/30/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation

class GameManager {
    var gameScore: (serverScore: Int, receiverScore: Int) = (0, 0) {
        didSet {
            if gameScore != (0, 0) {
                if isTiebreak && (playerOneGameScore + playerTwoGameScore) % 2 == 1 {
                    switchServer()
                } else {
                    serverSwitchesSides()
                }
                gameEnded = false
            } else if gameScore == (0, 0) {
                gameEnded = true
            }
        }
    }
    
    var server: Player?
    var serverSide: ServingSide = .deuceCourt
    
    var playerOneGameScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            oldPlayerOneGameScore = oldValue
        }
    }
    
    var playerTwoGameScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            oldPlayerTwoGameScore = oldValue
        }
    }
    
    var isTiebreak = false
    var gameEnded = false
    
    var oldPlayerOneGameScore = 0
    var oldPlayerTwoGameScore = 0
    
    // Tennis scoring convention is to call out the server gameScore before the receiver gameScore.
    func updateScoreOrderBasedOnServer() {
        switch server {
        case .one?:
            gameScore = (playerOneGameScore, playerTwoGameScore)
        case .two?:
            gameScore = (playerTwoGameScore, playerOneGameScore)
        case .none:
            break
        }
    }
    
    func switchServer() {
        switch server {
        case .one?:
            server = .two
        case .two?:
            server = .one
        default:
            break
        }
    }
    
    func serverSwitchesSides() {
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
            switch gameScore {
            case (0...15, 0...40):
                playerOneGameScore += 15
            case (30, 0...40):
                playerOneGameScore += 10
            case (40, 0...30):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationAfterYouScored()
            }
        case .two?:
            switch gameScore {
            case (0...40, 0...15):
                playerOneGameScore += 15
            case (0...40, 30):
                playerOneGameScore += 10
            case (0...30, 40):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationAfterYouScored()
            }
        case .none:
            break
        }
    }
    
    func increasePointForPlayerTwo() {
        switch server {
        case .one?:
            switch gameScore {
            case (0...40, 0...15):
                playerTwoGameScore += 15
            case (0...40, 30):
                playerTwoGameScore += 10
            case (0...30, 40):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationAfterOpponentScored()
            }
        case .two?:
            switch gameScore {
            case (0...15, 0...40):
                playerTwoGameScore += 15
            case (30, 0...40):
                playerTwoGameScore += 10
            case (40, 0...30):
                scoreWinningPoint()
            default:
                enterDeuceOrAdvantageSituationAfterOpponentScored()
            }
        case .none:
            break
        }
    }
    
    func increaseTiebreakPointForPlayerOne() {
        playerOneGameScore += 1
        if (playerOneGameScore >= 7) && (playerOneGameScore >= playerTwoGameScore + 2) {
            scoreWinningPoint()
        }
    }
    
    func increaseTiebreakPointForPlayerTwo() {
        playerTwoGameScore += 1
        if (playerTwoGameScore >= 7) && (playerTwoGameScore >= playerOneGameScore + 2) {
            scoreWinningPoint()
        }
    }
    
    func enterDeuceOrAdvantageSituationAfterYouScored() {
        if playerOneGameScore == playerTwoGameScore + 10 {
            playerOneGameScore += 10
        } else if playerOneGameScore == playerTwoGameScore - 1 {
            playerOneGameScore += 1
        } else if playerOneGameScore == playerTwoGameScore {
            playerOneGameScore += 1
        } else if playerOneGameScore == playerTwoGameScore + 1 {
            scoreWinningPoint()
        }
    }
    
    func enterDeuceOrAdvantageSituationAfterOpponentScored() {
        if playerTwoGameScore == playerOneGameScore + 10 {
            playerTwoGameScore += 10
        } else if playerTwoGameScore == playerOneGameScore - 1 {
            playerTwoGameScore += 1
        } else if playerTwoGameScore == playerOneGameScore {
            playerTwoGameScore += 1
        } else if playerTwoGameScore == playerOneGameScore + 1 {
            scoreWinningPoint()
        }
    }
    
    func scoreWinningPoint() {
        playerOneGameScore = 0
        playerTwoGameScore = 0
        switchServer()
    }
}

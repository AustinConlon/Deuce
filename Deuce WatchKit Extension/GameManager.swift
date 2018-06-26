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
                    changeServer()
                } else {
                    updateServingSide()
                }
                gameEnded = false
            } else if gameScore == (0, 0) {
                gameEnded = true
            }
        }
    }
    var server: Player? {
        didSet {
            updateServingSide()
        }
    }
    var servingSide: ServingSide?
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
    var oldPlayerOneGameScore = 0
    var oldPlayerTwoGameScore = 0
    var isTiebreak = false
    var gameEnded = false
    
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
    
    func updateServingSide() {
        switch (server, servingSide) {
        case (.one?, nil):
            servingSide = .right
        case (.two?, nil):
            servingSide = .left
        default:
            serverSwitchesSides()
        }
    }
    
    func serverSwitchesSides() {
        switch (server, servingSide) {
        case (.one?, .right?):
            servingSide = .left
        case (.one?, .left?):
            servingSide = .right
        case (.two?, .left?):
            servingSide = .right
        case (.two?, .right?):
            servingSide = .left
        default:
            break
        }
    }
    
    func changeServer() {
        switch server { // Other player now serves.
        case .one?:
            server = .two
            switch isTiebreak {
            case true:
                servingSide = .right
            case false:
                servingSide = .left
            }
        case .two?:
            server = .one
            switch isTiebreak {
            case true:
                servingSide = .left
            case false:
                servingSide = .right
            }
        case .none:
            break
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
                winGame()
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
                winGame()
            default:
                enterDeuceOrAdvantageSituationAfterYouScored()
            }
        case .none:
            break
        }
    }
    
    func increasePointForPlayerTwo() {
        switch server {
        case .two?:
            switch gameScore {
            case (0...15, 0...40):
                playerTwoGameScore += 15
            case (30, 0...40):
                playerTwoGameScore += 10
            case (40, 0...30):
                winGame()
            default:
                enterDeuceOrAdvantageSituationAfterOpponentScored()
            }
        case .one?:
            switch gameScore {
            case (0...40, 0...15):
                playerTwoGameScore += 15
            case (0...40, 30):
                playerTwoGameScore += 10
            case (0...30, 40):
                winGame()
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
            winGame()
        }
    }
    
    func increaseTiebreakForPlayerTwo() {
        playerTwoGameScore += 1
        if (playerTwoGameScore >= 7) && (playerTwoGameScore >= playerOneGameScore + 2) {
            winGame()
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
            winGame()
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
            winGame()
        }
    }
    
    func winGame() {
        playerOneGameScore = 0
        playerTwoGameScore = 0
        changeServer()
    }
}

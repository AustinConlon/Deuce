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
                if isTiebreaker && (yourGameScore + opponentGameScore) % 2 == 1 {
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
    var yourGameScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
        }
    }
    var opponentGameScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
        }
    }
    var isTiebreaker = false
    var gameEnded = false
    
    // Tennis scoring convention is to call out the server gameScore before the receiver gameScore.
    func updateScoreOrderBasedOnServer() {
        switch server {
        case .you?:
            gameScore = (yourGameScore, opponentGameScore)
        case .opponent?:
            gameScore = (opponentGameScore, yourGameScore)
        case .none:
            break
        }
    }
    
    func updateServingSide() {
        switch (server, servingSide) {
        case (.you?, nil):
            servingSide = .right
        case (.opponent?, nil):
            servingSide = .left
        default:
            serverSwitchesSides()
        }
    }
    
    func serverSwitchesSides() {
        switch (server, servingSide) {
        case (.you?, .right?):
            servingSide = .left
        case (.you?, .left?):
            servingSide = .right
        case (.opponent?, .left?):
            servingSide = .right
        case (.opponent?, .right?):
            servingSide = .left
        default:
            break
        }
    }
    
    func changeServer() {
        switch server { // Other player now serves.
        case .you?:
            server = .opponent
            switch isTiebreaker {
            case true:
                servingSide = .right
            case false:
                servingSide = .left
            }
        case .opponent?:
            server = .you
            switch isTiebreaker {
            case true:
                servingSide = .left
            case false:
                servingSide = .right
            }
        case .none:
            break
        }
    }
    
    func scorePointForYou() {
        switch server {
        case .you?:
            switch gameScore {
            case (0...15, 0...40):
                yourGameScore += 15
            case (30, 0...40):
                yourGameScore += 10
            case (40, 0...30):
                winGame()
            default:
                enterDeuceOrAdvantageSituationAfterYouScored()
            }
        case .opponent?:
            switch gameScore {
            case (0...40, 0...15):
                yourGameScore += 15
            case (0...40, 30):
                yourGameScore += 10
            case (0...30, 40):
                winGame()
            default:
                enterDeuceOrAdvantageSituationAfterYouScored()
            }
        case .none:
            break
        }
    }
    
    func scorePointForOpponent() {
        switch server {
        case .opponent?:
            switch gameScore {
            case (0...15, 0...40):
                opponentGameScore += 15
            case (30, 0...40):
                opponentGameScore += 10
            case (40, 0...30):
                winGame()
            default:
                enterDeuceOrAdvantageSituationAfterOpponentScored()
            }
        case .you?:
            switch gameScore {
            case (0...40, 0...15):
                opponentGameScore += 15
            case (0...40, 30):
                opponentGameScore += 10
            case (0...30, 40):
                winGame()
            default:
                enterDeuceOrAdvantageSituationAfterOpponentScored()
            }
        case .none:
            break
        }
    }
    
    func scoreTiebreakForYou() {
        yourGameScore += 1
        if (yourGameScore >= 7) && (yourGameScore >= opponentGameScore + 2) {
            winGame()
        }
    }
    
    func scoreTiebreakForOpponent() {
        opponentGameScore += 1
        if (opponentGameScore >= 7) && (opponentGameScore >= yourGameScore + 2) {
            winGame()
        }
    }
    
    func enterDeuceOrAdvantageSituationAfterYouScored() {
        if yourGameScore == opponentGameScore + 10 {
            yourGameScore += 10
        } else if yourGameScore == opponentGameScore - 1 {
            yourGameScore += 1
        } else if yourGameScore == opponentGameScore {
            yourGameScore += 1
        } else if yourGameScore == opponentGameScore + 1 {
            winGame()
        }
    }
    
    func enterDeuceOrAdvantageSituationAfterOpponentScored() {
        if opponentGameScore == yourGameScore + 10 {
            opponentGameScore += 10
        } else if opponentGameScore == yourGameScore - 1 {
            opponentGameScore += 1
        } else if opponentGameScore == yourGameScore {
            opponentGameScore += 1
        } else if opponentGameScore == yourGameScore + 1 {
            winGame()
        }
    }
    
    func winGame() {
        yourGameScore = 0
        opponentGameScore = 0
        changeServer()
    }
}

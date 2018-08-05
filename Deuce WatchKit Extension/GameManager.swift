//
//  GameManager.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/30/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation

class GameManager {
    var server: Player? {
        didSet {
            oldServer = oldValue
            serverSide = .deuceCourt
        }
    }
    
    var serverSide: ServingSide = .deuceCourt {
        didSet {
            oldServerSide = oldValue
        }
    }
    
    var oldServer: Player?
    var oldServerSide: ServingSide?
    
    var gameScore: (Int, Int) {
        get {
           return (serverGameScore, receiverGameScore)
        }
    }
    
    var oldGameScore: (Int, Int) {
        get {
            return (oldServerGameScore, oldReceiverGameScore)
        }
    }
    
    var playerOneGameScore = 0 {
        didSet {
            oldPlayerOneGameScore = oldValue
            switch isTiebreak {
            case true:
                if (playerOneGameScore + playerTwoGameScore) % 2 == 0 {
                    serverSwitchesSides()
                } else {
                    switchServer()
                }
            default:
                if serverGameScore > 0 || receiverGameScore > 0 {
                    serverSwitchesSides()
                } else if gameScore == (0, 0) {
                    serverSide = .deuceCourt
                }
            }
        }
    }
    
    var playerTwoGameScore = 0 {
        didSet {
            oldPlayerTwoGameScore = oldValue
            switch isTiebreak {
            case true:
                if (playerOneGameScore + playerTwoGameScore) % 2 == 0 {
                    serverSwitchesSides()
                } else {
                    switchServer()
                }
            default:
                if serverGameScore > 0 || receiverGameScore > 0 {
                    serverSwitchesSides()
                } else if gameScore == (0, 0) {
                    serverSide = .deuceCourt
                }
            }
        }
    }
    
    var serverGameScore: Int {
        get {
            if server == .one {
                return playerOneGameScore
            } else {
                return playerTwoGameScore
            }
        }
    }
    
    var receiverGameScore: Int {
        get {
            if server == .one {
                return playerTwoGameScore
            } else {
                return playerOneGameScore
            }
        }
    }
    
    var oldServerGameScore: Int {
        get {
            if server == .one {
                return oldPlayerOneGameScore!
            } else {
                return oldPlayerTwoGameScore!
            }
        }
    }
    
    var oldReceiverGameScore: Int {
        get {
            if server == .one {
                return oldPlayerTwoGameScore!
            } else {
                return oldPlayerOneGameScore!
            }
        }
    }
    
    var isTiebreak = false
    var isFinished = false
    
    var oldPlayerOneGameScore: Int?
    var oldPlayerTwoGameScore: Int?
    
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
        isFinished = true
        switchServer()
        
        if isTiebreak {
            serverSide = .adCourt
        }
    }
}

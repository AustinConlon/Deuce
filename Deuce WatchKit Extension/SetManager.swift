//
//  SetManager.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/29/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation

enum TypeOfSet {
    case advantage, tiebreak
}

class SetManager {
    let minimumNumbersOfGamesToWinSet = 6
    static var typeOfSet: TypeOfSet = .tiebreak
    
    var setScore: (Int, Int) {
        get {
            return (serverSetScore, receiverSetScore)
        }
    }
    
    var playerOneSetScore = 0 {
        didSet {
            if (playerOneSetScore >= 6) && (playerOneSetScore - playerTwoSetScore >= marginToWinSetBy) { // You win the set.
                isFinished = true
            }
            oldPlayerOneSetScore = oldValue
        }
    }
    
    var playerTwoSetScore = 0 {
        didSet {
            if (playerTwoSetScore >= 6) && (playerTwoSetScore - playerOneSetScore >= marginToWinSetBy) { // Opponent wins the set.
                isFinished = true
            }
            oldPlayerTwoSetScore = oldValue
        }
    }
    
    var serverSetScore: Int {
        get {
            if currentGame.server == .one {
                return playerOneSetScore
            } else {
                return playerTwoSetScore
            }
        }
    }
    
    var receiverSetScore: Int {
        get {
            if currentGame.server == .one {
                return playerTwoSetScore
            } else {
                return playerOneSetScore
            }
        }
    }
    
    var oldPlayerOneSetScore: Int?
    var oldPlayerTwoSetScore: Int?
    
    var marginToWinSetBy: Int {
        get {
            if (SetManager.typeOfSet == .tiebreak) && (currentGame.isTiebreak) {
                return 1
            } else {
                return 2
            }
        }
    }
    
    var isFinished = false
    
    var games = [GameManager]() {
        didSet {
            if SetManager.typeOfSet == .tiebreak && setScore == (6, 6) {
                currentGame.isTiebreak = true
            } else {
                currentGame.isTiebreak = false
            }
            
            games.last?.server = oldValue.last?.server
            currentGame.oldServer = oldValue.last?.oldServer
            currentGame.oldServerSide = oldValue.last?.oldServerSide
            if games.count < oldValue.count {
                currentGame.server = currentGame.oldServer
                currentGame.serverSide = currentGame.oldServerSide!
            }
        }
    }
    var currentGame: GameManager {
        get {
            return games.last!
        }
    }
    
    init() {
        games.append(GameManager())
    }
}

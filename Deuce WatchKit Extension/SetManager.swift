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
            if (playerOneSetScore >= 6) && (playerOneSetScore - playerTwoSetScore >= marginToWinSetBy) { // Player one wins the set.
                isFinished = true
            }
        }
    }
    
    var playerTwoSetScore = 0 {
        didSet {
            if (playerTwoSetScore >= 6) && (playerTwoSetScore - playerOneSetScore >= marginToWinSetBy) { // Player two wins the set.
                isFinished = true
            }
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
            if games.count > oldValue.count || self.isFinished { // Added new game.
                switch oldValue.last?.server! {
                case .one?:
                    games.last?.server = .two
                case .two?:
                    games.last?.server = .one
                default:
                    break
                }
            }
            
            if SetManager.typeOfSet == .tiebreak && setScore == (6, 6) {
                currentGame.isTiebreak = true
            } else {
                currentGame.isTiebreak = false
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

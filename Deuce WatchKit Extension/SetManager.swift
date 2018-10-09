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
    
    var score: (Int, Int) {
        get {
            return (serverScore, receiverScore)
        }
    }
    
    var playerOneScore = 0 {
        didSet {
            if (playerOneScore >= 6) && (playerOneScore - playerTwoScore >= marginToWinSetBy) { // Player one wins the set.
                isFinished = true
            }
        }
    }
    
    var playerTwoScore = 0 {
        didSet {
            if (playerTwoScore >= 6) && (playerTwoScore - playerOneScore >= marginToWinSetBy) { // Player two wins the set.
                isFinished = true
            }
        }
    }
    
    var serverScore: Int {
        get {
            if currentGame.server == .one {
                return playerOneScore
            } else {
                return playerTwoScore
            }
        }
    }
    
    var receiverScore: Int {
        get {
            if currentGame.server == .one {
                return playerTwoScore
            } else {
                return playerOneScore
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
            
            if SetManager.typeOfSet == .tiebreak && score == (6, 6) {
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

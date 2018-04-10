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
    
    // Number of games you and your opponent won.
    var setScore: (serverScore: Int, receiverScore: Int) = (0, 0)
    
    var playerOneSetScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if (playerOneSetScore >= 6) && (playerOneSetScore - playerTwoSetScore >= marginToWinSetBy) { // You win the set.
                setEnded = true
            }
        }
    }
    
    var playerTwoSetScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if (playerTwoSetScore >= 6) && (playerTwoSetScore - playerOneSetScore >= marginToWinSetBy) { // Opponent wins the set.
                setEnded = true
            }
        }
    }
    
    var marginToWinSetBy: Int {
        get {
            if (SetManager.typeOfSet == .tiebreak) && (currentGame.isTiebreaker) {
                return 1
            } else {
                return 2
            }
        }
    }
    
    var setEnded = false
    
    var games = [GameManager]() {
        didSet {
            if SetManager.typeOfSet == .tiebreak && setScore == (6, 6) {
                currentGame.isTiebreaker = true
            }
            // Persist state of which player is the server across games.
            games.last?.server = oldValue.last?.server
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
    
    // Tennis scoring convention is to call out the server score before the receiver score.
    func updateScoreOrderBasedOnServer() {
        switch currentGame.server {
        case .one?:
            setScore = (playerOneSetScore, playerTwoSetScore)
        case .two?:
            setScore = (playerTwoSetScore, playerOneSetScore)
        case .none:
            break
        }
    }
}

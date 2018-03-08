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
    static var typeOfSet: TypeOfSet?
    
    // Number of games you and your opponent won.
    var setScore: (serverScore: Int, receiverScore: Int) = (0, 0)
    
    var yourSetScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if (yourSetScore >= 6) && (yourSetScore - opponentSetScore >= marginToWinSetBy) { // You win the set.
                setEnded = true
            }
        }
    }
    
    var opponentSetScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if (opponentSetScore >= 6) && (opponentSetScore - yourSetScore >= marginToWinSetBy) { // Opponent wins the set.
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
        case .you?:
            setScore = (yourSetScore, opponentSetScore)
        case .opponent?:
            setScore = (opponentSetScore, yourSetScore)
        case .none:
            break
        }
    }
}

//
//  MatchManager.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/29/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation

class MatchManager {
    var minumumNumberOfSetsToWinMatch: Int { // Best-of series, e.g. a best-of 5 match ends with the first to win 3 sets
        get {
            switch maximumNumberOfSetsInMatch {
            case 3:
                return 2
            case 5:
                return 3
            default:
                return 1
            }
        }
    }
    var maximumNumberOfSetsInMatch: Int  // Default match length is 1 set.
    static var coinTossWinner: Player {  // Winner of the coin toss decides whether to serve or receive first.
        get {
            if ((arc4random_uniform(2)) == 0) {
                return .you
            } else {
                return .opponent
            }
        }
    }
    // Number of sets you and your opponent won.
    var matchScore: (serverScore: Int, receiverScore: Int) = (0, 0)
    var yourMatchScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if yourMatchScore >= minumumNumberOfSetsToWinMatch {
                matchEnded = true
                winner = .you
            }
        }
    }
    var opponentMatchScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if opponentMatchScore >= minumumNumberOfSetsToWinMatch {
                matchEnded = true
                winner = .opponent
            }
        }
    }
    var matchEnded = false
    var winner: Player?
    var sets = [SetManager]() {
        didSet {
            // Persist state of serving player across games.
            sets.last?.currentGame.server = oldValue.last?.currentGame.server
            currentSet.setEnded = false
        }
    }
    var currentSet: SetManager {
        get {
            return sets.last!
        }
    }
    var currentGame: GameManager {
        get {
            return currentSet.currentGame
        }
    }
    
    init(_ maximumNumberOfSetsInMatch: Int, _ typeOfSet: TypeOfSet, playerThatWillServeFirst: Player) {
        self.maximumNumberOfSetsInMatch = maximumNumberOfSetsInMatch
        sets.append(SetManager())
        sets[0].games[0].server = playerThatWillServeFirst
        SetManager.typeOfSet = typeOfSet
    }
    
    // Tennis scoring convention is to call out the server score before the receiver score.
    func updateScoreOrderBasedOnServer() {
        switch currentGame.server {
        case .you?:
            matchScore = (yourMatchScore, opponentMatchScore)
        case .opponent?:
            matchScore = (opponentMatchScore, yourMatchScore)
        case .none:
            break
        }
    }
    
    func scorePointForYouInCurrentGame() {
        switch currentGame.isTiebreaker {
        case true:
            currentGame.scoreTiebreakForYou()
        default:
            currentGame.scorePointForYou()
        }
        checkYouWonGame()
    }
    
    func scorePointForOpponentInCurrentGame() {
        switch currentGame.isTiebreaker {
        case true:
            currentGame.scoreTiebreakForOpponent()
        default:
            currentGame.scorePointForOpponent()
        }
        checkOpponentWonGame()
    }
    
    func checkYouWonGame() {
        if currentGame.gameEnded == true {
            currentSet.yourSetScore += 1
            currentSet.games.append(GameManager())
        }
        checkYouWonSet()
    }
    
    func checkOpponentWonGame() {
        if currentGame.gameEnded == true {
            currentSet.opponentSetScore += 1
            currentSet.games.append(GameManager())
        }
        checkOpponentWonSet()
    }
    
    func checkYouWonSet() {
        if currentSet.setEnded == true {
            yourMatchScore += 1
            if matchEnded == false {
                sets.append(SetManager())
            }
        }
    }
    
    func checkOpponentWonSet() {
        if currentSet.setEnded == true {
            opponentMatchScore += 1
            if matchEnded == false {
                sets.append(SetManager())
            }
        }
    }
}

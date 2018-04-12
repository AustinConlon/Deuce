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
                return .one
            } else {
                return .two
            }
        }
    }
    // Number of sets you and your opponent won.
    var matchScore: (serverScore: Int, receiverScore: Int) = (0, 0)
    var playerOneMatchScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if playerOneMatchScore >= minumumNumberOfSetsToWinMatch {
                matchEnded = true
                winner = .one
            }
        }
    }
    var playerTwoMatchScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if playerTwoMatchScore >= minumumNumberOfSetsToWinMatch {
                matchEnded = true
                winner = .two
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
    var totalNumberOfGamesPlayed: Int {
        var totalNumberOfGamesPlayed = 0
        for set in sets {
            totalNumberOfGamesPlayed += set.playerOneSetScore
            totalNumberOfGamesPlayed += set.playerTwoSetScore
//            for game in set.games {
//                totalNumberOfPointsPlayed += game.playerOneGameScore
//                totalNumberOfPointsPlayed += game.playerTwoGameScore
//            }
        }
        return totalNumberOfGamesPlayed
    }
    
    init(_ maximumNumberOfSetsInMatch: Int, _ typeOfSet: TypeOfSet, _ playerThatWillServeFirst: Player) {
        self.maximumNumberOfSetsInMatch = maximumNumberOfSetsInMatch
        sets.append(SetManager())
        sets[0].games[0].server = playerThatWillServeFirst
        SetManager.typeOfSet = typeOfSet
    }
    
    // Tennis scoring convention is to call out the server score before the receiver score.
    func updateScoreOrderBasedOnServer() {
        switch currentGame.server {
        case .one?:
            matchScore = (playerOneMatchScore, playerTwoMatchScore)
        case .two?:
            matchScore = (playerTwoMatchScore, playerOneMatchScore)
        case .none:
            break
        }
    }
    
    func scorePointForPlayerOneInCurrentGame() {
        switch currentGame.isTiebreaker {
        case true:
            currentGame.scoreTiebreakForYou()
        default:
            currentGame.scorePointForPlayerOne()
        }
        checkYouWonGame()
    }
    
    func scorePointForPlayerTwoInCurrentGame() {
        switch currentGame.isTiebreaker {
        case true:
            currentGame.scoreTiebreakForOpponent()
        default:
            currentGame.scorePointForPlayerTwo()
        }
        checkOpponentWonGame()
    }
    
    func checkYouWonGame() {
        if currentGame.gameEnded == true {
            currentSet.playerOneSetScore += 1
            currentSet.games.append(GameManager())
        }
        checkYouWonSet()
    }
    
    func checkOpponentWonGame() {
        if currentGame.gameEnded == true {
            currentSet.playerTwoSetScore += 1
            currentSet.games.append(GameManager())
        }
        checkOpponentWonSet()
    }
    
    func checkYouWonSet() {
        if currentSet.setEnded == true {
            playerOneMatchScore += 1
            if matchEnded == false {
                sets.append(SetManager())
            }
        }
    }
    
    func checkOpponentWonSet() {
        if currentSet.setEnded == true {
            playerTwoMatchScore += 1
            if matchEnded == false {
                sets.append(SetManager())
            }
        }
    }
}

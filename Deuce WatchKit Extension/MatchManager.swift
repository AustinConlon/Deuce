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
            let flippedHeads = Bool.random()
            if flippedHeads {
                return .one
            } else {
                return .two
            }
        }
    }
    
    // Number of sets you and your opponent won.
    var score: (serverScore: Int, receiverScore: Int) = (0, 0)
    var playerOneScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if playerOneScore >= minumumNumberOfSetsToWinMatch {
                isFinished = true
                winner = .one
            }
        }
    }
    var playerTwoScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if playerTwoScore >= minumumNumberOfSetsToWinMatch {
                isFinished = true
                winner = .two
            }
        }
    }
    
    var isFinished = false
    
    var winner: Player?
    var sets = [SetManager]() {
        didSet {
            if sets.count > oldValue.count {
                switch oldValue.last?.games.last?.server {
                case .one?:
                    sets.last?.games.last?.server = .two
                case .two?:
                    sets.last?.games.last?.server = .one
                default:
                    break
                }
            }
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
            totalNumberOfGamesPlayed += set.playerOneScore
            totalNumberOfGamesPlayed += set.playerTwoScore
        }
        return totalNumberOfGamesPlayed
    }
    
    // MARK: Initialization
    
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
            score = (playerOneScore, playerTwoScore)
        case .two?:
            score = (playerTwoScore, playerOneScore)
        case .none:
            break
        }
    }
    
    func scorePointForPlayerOne() {
        switch currentGame.isTiebreak {
        case true:
            currentGame.increaseTiebreakPointForPlayerOne()
        default:
            currentGame.increasePointForPlayerOne()
        }
        checkPlayerOneWonGame()
    }
    
    func scorePointForPlayerTwo() {
        switch currentGame.isTiebreak {
        case true:
            currentGame.increaseTiebreakPointForPlayerTwo()
        default:
            currentGame.increasePointForPlayerTwo()
        }
        checkPlayerTwoWonGame()
    }
    
    func increaseSetPointForPlayerOneInCurrentGame() {
        currentGame.scoreWinningPoint()
        currentSet.playerOneScore += 1
        checkPlayerOneWonSet()
    }
    
    func increaseSetPointForPlayerTwoInCurrentGame() {
        currentGame.scoreWinningPoint()
        currentSet.playerTwoScore += 1
        checkPlayerTwoWonSet()
    }
    
    func checkPlayerOneWonGame() {
        if currentGame.isFinished {
            currentSet.playerOneScore += 1
            checkPlayerOneWonSet()
        }
    }

    func checkPlayerTwoWonGame() {
        if currentGame.isFinished {
            currentSet.playerTwoScore += 1
            checkPlayerTwoWonSet()
        }
    }
    
    func checkPlayerOneWonSet() {
        if currentSet.isFinished == true {
            playerOneScore += 1
            if self.isFinished == false {
                sets.append(SetManager())
            }
        } else {
            currentSet.games.append(GameManager())
        }
    }
    
    func checkPlayerTwoWonSet() {
        if currentSet.isFinished == true {
            playerTwoScore += 1
            if self.isFinished == false {
                sets.append(SetManager())
            }
        } else {
            currentSet.games.append(GameManager())
        }
    }
    
    func undoPlayerOneScore() {
        if currentGame.score == (0, 0) {
            if currentSet.games.count > 1 {
                currentSet.games.removeLast()
                currentSet.playerOneScore -= 1
                sets.last?.games.last?.isTiebreak = false
            } else if currentSet.games.count == 1 && sets.count > 1 {
                sets.removeLast()
                currentSet.playerOneScore -= 1
                playerOneScore -= 1
            }
            
            currentGame.isFinished = false
            currentSet.isFinished = false
        } else {
            currentGame.playerOneScore = currentGame.oldPlayerOneScore!
            if currentGame.isTiebreak {
                if currentGame.score == (0, 0) {
                    currentGame.changeServer()
                } else if (currentGame.playerOneScore + currentGame.playerTwoScore) % 2 == 0 {
                    currentGame.changeServer()
                    currentGame.serverSide = .deuceCourt
                } else {
                    currentGame.changeServerSide()
                }
            }
        }
    }
    
    func undoPlayerTwoScore() {
        if currentGame.score == (0, 0) {
            if currentSet.games.count > 1 {
                currentSet.games.removeLast()
                currentSet.playerTwoScore -= 1
            } else if currentSet.games.count == 1 && sets.count > 1 {
                sets.removeLast()
                currentSet.playerTwoScore -= 1
                playerTwoScore -= 1
            }
            
            currentGame.isFinished = false
            currentSet.isFinished = false
        } else {
            currentGame.playerTwoScore = currentGame.oldPlayerTwoScore!
            if currentGame.isTiebreak {
                if currentGame.score == (0, 0) {
                    currentGame.changeServer()
                } else if (currentGame.playerOneScore + currentGame.playerTwoScore) % 2 == 0 {
                    currentGame.changeServer()
                    currentGame.serverSide = .deuceCourt
                } else {
                    currentGame.changeServerSide()
                }
            }
        }
    }
}

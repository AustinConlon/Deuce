//
//  ScoreManager.swift
//  Deuce
//
//  Created by Austin Conlon on 2/6/18.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation

enum Player {
    case one, two
}

enum ServingSide {
    // Right side of the court's hash mark from the serving player's perspective.
    case deuceCourt
    // Left side of the court's hash mark from the serving player's perspective.
    case adCourt
}

enum TypeOfSet {
    case advantage
    case tiebreak
}

enum State {
    case notStarted
    case playing
    case finished
}

class Score {
    var currentMatch: MatchManager
    init(_ match: MatchManager) {
        self.currentMatch = match
    }
}

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
                matchState = .finished
                winner = .one
            }
        }
    }
    
    var playerTwoScore = 0 {
        didSet {
            updateScoreOrderBasedOnServer()
            if playerTwoScore >= minumumNumberOfSetsToWinMatch {
                matchState = .finished
                winner = .two
            }
        }
    }
    
    var matchState: State = .notStarted
    
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
        matchState = .playing
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
    
    func scorePoint(for player: Player) {
        switch currentGame.isTiebreak {
        case true:
            currentGame.scorePointInTiebreak(for: player)
        default:
            currentGame.increasePoint(for: player)
        }
        checkGameWon(for: player)
    }
    
    func checkGameWon(for player: Player) {
        if currentGame.gameState == .finished {
            switch player {
            case .one:
                currentSet.playerOneScore += 1
            case .two:
                currentSet.playerTwoScore += 1
            }
            checkSetWon(for: player)
        }
    }
    
    func checkSetWon(for player: Player) {
        switch currentSet.setState {
        case .finished:
            switch player {
            case .one:
                playerOneScore += 1
                if matchState == .playing {
                    sets.append(SetManager())
                }
            case .two:
                playerTwoScore += 1
                if matchState == .playing {
                    sets.append(SetManager())
                }
            }
        default:
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
            
            currentGame.gameState = .playing
            currentSet.setState = .playing
            currentGame.isTiebreak = false
        } else {
            if currentGame.isTiebreak {
                if currentGame.score == (0, 0) {
                    currentGame.changeServer()
                } else if (currentGame.player1Score + currentGame.player2Score) % 2 == 1 {
                    currentGame.changeServer()
                    currentGame.serverSide = .deuceCourt
                } else {
                    currentGame.changeServerSide()
                }
                currentGame.player1Score = currentGame.oldPlayerOneScore!
            } else {
                currentGame.player1Score = currentGame.oldPlayerOneScore!
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
            
            currentGame.gameState = .playing
            currentSet.setState = .playing
            currentGame.isTiebreak = false
        } else {
            if currentGame.isTiebreak {
                if currentGame.score == (0, 0) {
                    currentGame.changeServer()
                } else if (currentGame.player1Score + currentGame.player2Score) % 2 == 1 {
                    currentGame.changeServer()
                    currentGame.serverSide = .deuceCourt
                } else {
                    currentGame.changeServerSide()
                }
                currentGame.player2Score = currentGame.oldPlayerTwoScore!
            } else {
                currentGame.player2Score = currentGame.oldPlayerTwoScore!
            }
        }
    }
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
                setState = .finished
            }
        }
    }
    
    var playerTwoScore = 0 {
        didSet {
            if (playerTwoScore >= 6) && (playerTwoScore - playerOneScore >= marginToWinSetBy) { // Player two wins the set.
                setState = .finished
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
    
    var setState: State = .notStarted
    
    var games = [GameManager]() {
        didSet {
            if games.count > oldValue.count || setState == .finished { // Added new game.
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
    
    var isOddGameFinished: Bool {
        get {
            print(games.count)
            if (games.count - 1) % 2 == 1 {
                return true
            } else {
                return false
            }
        }
    }
    
    init() {
        games.append(GameManager())
    }
}

class GameManager {
    var serverSide: ServingSide = .deuceCourt
    
    var server: Player? {
        didSet {
            switch isTiebreak {
            case true:
                serverSide = .adCourt
            case false:
                serverSide = .deuceCourt
            }
        }
    }
    
    // For conveniently switching on the game score.
    var score: (Int, Int) {
        get {
            return (serverScore, receiverScore)
        }
    }
    
    var player1Score = 0 {
        didSet {
            oldPlayerOneScore = oldValue
            switch isTiebreak {
            case true:
                if player1Score > oldValue {
                    if (player1Score + player2Score) % 2 == 0 {
                        changeServerSide()
                    } else { // Undo.
                        changeServer()
                    }
                }
            case false:
                changeServerSide()
            }
        }
    }
    
    var player2Score = 0 {
        didSet {
            oldPlayerTwoScore = oldValue
            switch isTiebreak {
            case true:
                if player2Score > oldValue {
                    if (player1Score + player2Score) % 2 == 0 {
                        changeServerSide()
                    } else { // Undo.
                        changeServer()
                    }
                }
            case false:
                changeServerSide()
            }
        }
    }
    
    var serverScore: Int {
        get {
            if server == .one {
                return player1Score
            } else {
                return player2Score
            }
        }
    }
    
    var receiverScore: Int {
        get {
            if server == .one {
                return player2Score
            } else {
                return player1Score
            }
        }
    }
    
    var isTiebreak = false
    
    var gameState: State = .notStarted
    
    var oldPlayerOneScore: Int?
    var oldPlayerTwoScore: Int?
    
    func changeServer() {
        switch server {
        case .one?:
            server = .two
        case .two?:
            server = .one
        default:
            break
        }
    }
    
    func changeServerSide() {
        switch serverSide {
        case .deuceCourt:
            serverSide = .adCourt
        case .adCourt:
            serverSide = .deuceCourt
        }
    }
    
    func increasePoint(for player: Player) {
        switch player {
        case .one:
            switch server {
            case .one?:
                switch score {
                case (0...15, 0...40):
                    player1Score += 15
                case (30, 0...40):
                    player1Score += 10
                case (40, 0...30):
                    scoreWinningPoint()
                default:
                    enterDeuceOrAdvantageSituationForPlayerOne()
                }
            case .two?:
                switch score {
                case (0...40, 0...15):
                    player1Score += 15
                case (0...40, 30):
                    player1Score += 10
                case (0...30, 40):
                    scoreWinningPoint()
                default:
                    enterDeuceOrAdvantageSituationForPlayerOne()
                }
            case .none:
                break
            }
        case .two:
            switch server {
            case .one?:
                switch score {
                case (0...40, 0...15):
                    player2Score += 15
                case (0...40, 30):
                    player2Score += 10
                case (0...30, 40):
                    scoreWinningPoint()
                default:
                    enterDeuceOrAdvantageSituationForPlayerTwo()
                }
            case .two?:
                switch score {
                case (0...15, 0...40):
                    player2Score += 15
                case (30, 0...40):
                    player2Score += 10
                case (40, 0...30):
                    scoreWinningPoint()
                default:
                    enterDeuceOrAdvantageSituationForPlayerTwo()
                }
            case .none:
                break
            }
        }
        
    }
    
    func scorePointInTiebreak(for player: Player) {
        switch player {
        case .one:
            player1Score += 1
            if (player1Score >= 7) && (player1Score >= player2Score + 2) {
                scoreWinningPoint()
            }
        case .two:
            player2Score += 1
            if (player2Score >= 7) && (player2Score >= player1Score + 2) {
                scoreWinningPoint()
            }
        }
    }
    
    func enterDeuceOrAdvantageSituationForPlayerOne() {
        if player1Score == player2Score + 10 {
            player1Score += 10
        } else if player1Score == player2Score - 1 {
            player1Score += 1
        } else if player1Score == player2Score {
            player1Score += 1
        } else if player1Score == player2Score + 1 {
            scoreWinningPoint()
        }
    }
    
    func enterDeuceOrAdvantageSituationForPlayerTwo() {
        if player2Score == player1Score + 10 {
            player2Score += 10
        } else if player2Score == player1Score - 1 {
            player2Score += 1
        } else if player2Score == player1Score {
            player2Score += 1
        } else if player2Score == player1Score + 1 {
            scoreWinningPoint()
        }
    }
    
    func scoreWinningPoint() {
        gameState = .finished
    }
}

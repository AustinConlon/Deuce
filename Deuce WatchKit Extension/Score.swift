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

enum SetType {
    case tiebreak
    case superTiebreak
    case advantage
}

enum GameType {
    case standard
    case noAd
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
            switch maximumSetCount {
            case 3:
                return 2
            case 5:
                return 3
            default:
                return 1
            }
        }
    }
    
    var maximumSetCount: Int  // Default match length is 1 set.
    
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
                let oldGame = oldValue.last?.games.last
                
                switch oldGame?.isTiebreak {
                case false:
                    switch oldGame?.server {
                    case .one?:
                        sets.last?.games.last?.server = .two
                    case .two?:
                        sets.last?.games.last?.server = .one
                    default:
                        break
                    }
                case true:
                    switch oldGame?.serviceAtStartOfTiebreak {
                    case .one?:
                        sets.last?.games.last?.server = .two
                    case .two?:
                        sets.last?.games.last?.server = .one
                    default:
                        break
                    }
                default:
                    break
                }
            }
            
            if sets.count == 3 && SetManager.setType == .superTiebreak {
                GameManager.minimumPointsToWinTiebreak = 10
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
            totalNumberOfGamesPlayed += set.player1Score
            totalNumberOfGamesPlayed += set.player2Score
        }
        return totalNumberOfGamesPlayed
    }
    
    // MARK: Initialization
    init(_ maximumNumberOfSetsInMatch: Int, setType: SetType, gameType: GameType, _ playerThatWillServeFirst: Player) {
        self.maximumSetCount = maximumNumberOfSetsInMatch
        sets.append(SetManager())
        sets[0].games[0].server = playerThatWillServeFirst
        SetManager.setType = setType
        GameManager.gameType = gameType
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
            currentGame.scoreTiebreakPoint(for: player)
        default:
            currentGame.scorePoint(for: player)
        }
        checkGameWon(for: player)
    }
    
    func checkGameWon(for player: Player) {
        if currentGame.gameState == .finished {
            switch player {
            case .one:
                currentSet.player1Score += 1
            case .two:
                currentSet.player2Score += 1
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
    
    func undoPlayer1Score() {
        if currentGame.score == (0, 0) {
            if currentSet.games.count > 1 {
                currentSet.games.removeLast()
                currentSet.player1Score -= 1
                sets.last?.games.last?.isTiebreak = false
            } else if currentSet.games.count == 1 && sets.count > 1 {
                sets.removeLast()
                currentSet.player1Score -= 1
                self.playerOneScore -= 1
            }
            
            currentGame.gameState = .playing
            currentSet.setState = .playing
//            currentGame.isTiebreak = false
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
                currentGame.player1Score = currentGame.oldPlayer1Score!
            } else {
                currentGame.player1Score = currentGame.oldPlayer1Score!
            }
        }
    }
    
    func undoPlayer2Score() {
        if currentGame.score == (0, 0) {
            if currentSet.games.count > 1 {
                currentSet.games.removeLast()
                currentSet.player2Score -= 1
            } else if currentSet.games.count == 1 && sets.count > 1 {
                sets.removeLast()
                currentSet.player2Score -= 1
                self.playerTwoScore -= 1
            }
            
            currentGame.gameState = .playing
            currentSet.setState = .playing
//            currentGame.isTiebreak = false
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
                currentGame.player2Score = currentGame.oldPlayer2Score!
            } else {
                currentGame.player2Score = currentGame.oldPlayer2Score!
            }
        }
    }
}


class SetManager {
    let minimumNumbersOfGamesToWinSet = 6
    
    static var setType: SetType = .tiebreak
    
    var score: (Int, Int) {
        get {
            return (serverScore, receiverScore)
        }
    }
    
    var player1Score = 0 {
        didSet {
            if (player1Score >= 6) && (player1Score - player2Score >= minimumMarginToWin) { // Player one wins the set.
                setState = .finished
            }
        }
    }
    
    var player2Score = 0 {
        didSet {
            if (player2Score >= 6) && (player2Score - player1Score >= minimumMarginToWin) { // Player two wins the set.
                setState = .finished
            }
        }
    }
    
    var serverScore: Int {
        get {
            if currentGame.server == .one {
                return player1Score
            } else {
                return player2Score
            }
        }
    }
    
    var receiverScore: Int {
        get {
            if currentGame.server == .one {
                return player2Score
            } else {
                return player1Score
            }
        }
    }
    
    var minimumMarginToWin: Int {
        get {
            if (SetManager.setType == .tiebreak || SetManager.setType == .superTiebreak) && (currentGame.isTiebreak) {
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
            
            if (SetManager.setType == .tiebreak || SetManager.setType == .superTiebreak) && score == (6, 6) {
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
    
    var serviceAtStartOfTiebreak: Player?
    
    // For conveniently switching on the game score.
    var score: (Int, Int) {
        get {
            return (serverScore, receiverScore)
        }
    }
    
    var player1Score = 0 {
        didSet {
            oldPlayer1Score = oldValue
            
            if GameManager.gameType == .noAd && player1Score == 41 {
                gameState = .finished
            }
            
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
            oldPlayer2Score = oldValue
            
            if GameManager.gameType == .noAd && player2Score == 41 {
                gameState = .finished
            }
            
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
    
    var isTiebreak = false {
        didSet {
            if isTiebreak {
                serviceAtStartOfTiebreak = server
            }
        }
    }
    
    static var minimumPointsToWin = 4
    static var minimumPointsToWinTiebreak = 7
    
    static var gameType: GameType = .standard {
        didSet {
            switch gameType {
            case .standard:
                minimumPointsToWin = 4
            case .noAd:
                minimumPointsToWin = 3
            }
        }
    }
    
    var gameState: State = .notStarted
    
    var oldPlayer1Score: Int?
    var oldPlayer2Score: Int?
    
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
    
    func scorePoint(for player: Player) {
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
                    gameState = .finished
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
                    gameState = .finished
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
                    gameState = .finished
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
                    gameState = .finished
                default:
                    enterDeuceOrAdvantageSituationForPlayerTwo()
                }
            case .none:
                break
            }
        }
        
    }
    
    func scoreTiebreakPoint(for player: Player) {
        switch player {
        case .one:
            if (player1Score >= GameManager.minimumPointsToWinTiebreak - 1) && (player1Score >= player2Score + 1) {
                gameState = .finished
            } else {
                player1Score += 1
            }
        case .two:
            if (player2Score >= GameManager.minimumPointsToWinTiebreak - 1) && (player2Score >= player1Score + 1) {
                gameState = .finished
            } else {
                player2Score += 1
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
            gameState = .finished
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
            gameState = .finished
        }
    }
}

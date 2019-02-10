//
//  Score.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation

enum State {
    case playing
    case finished
}

enum Player {
    case player1
    case player2
}

enum Court {
    case deuceCourt
    case adCourt
}

enum SetType {
    case tiebreak
    case advantage
}

// MARK: Game
class Game {
    // Properties
    var servicePlayer: Player?
    var serviceSide: Court = .deuceCourt
    
    var score = [0, 0] {
        didSet {
            switch tiebreak {
            case true:
                if isOddPointConcluded {
                    serviceSide = .deuceCourt
                    
                    switch servicePlayer {
                    case .player1?:
                        servicePlayer = .player2
                    case .player2?:
                        servicePlayer = .player1
                    default:
                        break
                    }
                } else {
                    switch serviceSide {
                    case .deuceCourt:
                        serviceSide = .adCourt
                    case .adCourt:
                        serviceSide = .deuceCourt
                    }
                }
            case false:
                switch serviceSide {
                case .deuceCourt:
                    serviceSide = .adCourt
                case .adCourt:
                    serviceSide = .deuceCourt
                }
            }
        }
    }
    
    var servicePlayerScore: Int? {
        get {
            switch servicePlayer {
            case .player1?:
                return score[0]
            case .player2?:
                return score[1]
            default:
                return 0
            }
        }
    }
    
    var receiverPlayerScore: Int? {
        get {
            switch servicePlayer {
            case .player1?:
                return score[1]
            case .player2?:
                return score[0]
            default:
                return 0
            }
        }
    }
    
    static var pointNames = [
        0: "LOVE", 1: "15", 2: "30", 3: "40", 4: "AD"
    ]
    
    var isDeuce: Bool {
        if (score[0] >= 3 || score[1] >= 3) && score[0] == score[1] && !tiebreak {
            return true
        } else {
            return false
        }
    }
    
    var isBreakPoint: Bool {
        get {
            if let servicePlayerScore = servicePlayerScore, let receiverPlayerScore = receiverPlayerScore {
                if (receiverPlayerScore >= minimumToWin - 1) && (receiverPlayerScore >= servicePlayerScore + 1) && !tiebreak {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
    
    var minimumToWin = 4
    
    var isWinConditionMet: Bool {
        if (score[0] >= minimumToWin || score[1] >= minimumToWin) && (abs(score[0] - score[1]) >= 2) {
            return true
        } else {
            return false
        }
    }
    
    var winner: Player?
    var state: State = .playing
    
    var tiebreak = false {
        didSet {
            if tiebreak == true {
                minimumToWin = 7
                if score == [0, 0] {
                    serviceSide = .adCourt
                }
            }
        }
    }
    
    var isOddPointConcluded: Bool {
        get {
            if (score[0] + score[1]) % 2 == 1 {
                return true
            } else {
                return false
            }
        }
    }
    
    // Methods
    func scorePoint(for player: Player) {
        switch player {
        case .player1:
            score[0] += 1
        case .player2:
            score[1] += 1
        }
        
        if isDeuce {
            score[0] = 3
            score[1] = 3
        }
        
        if isWinConditionMet {
            winner = player
            state = .finished
        }
    }
    
    func getScore(for player: Player) -> String {
        switch (player, tiebreak) {
        case (.player1, false):
            return Game.pointNames[score[0]]!
        case (.player2, false):
            return Game.pointNames[score[1]]!
        case (.player1, true):
            return String(score[0])
        case (.player2, true):
            return String(score[1])
        }
    }
}

// MARK: Set
class Set {
    var score = [0, 0]
    
    var game = Game()
    var games = [Game]() {
        didSet {
            game = games.last!
            
            switch oldValue.last?.servicePlayer {
            case .player1?:
                game.servicePlayer = .player2
            case .player2?:
                game.servicePlayer = .player1
            default:
                break
            }
            
            if score == [6, 6] && Set.setType == .tiebreak {
                game.tiebreak = true
            }
        }
    }
    
    static var setType: SetType = .tiebreak
    
    var minimumToWin = 6
    
    var marginToWin: Int {
        get {
            switch game.tiebreak {
            case true:
                return 1
            case false:
                return 2
            }
        }
    }
    
    var isWinConditionMet: Bool {
        if (score[0] >= minimumToWin || score[1] >= minimumToWin) && (abs(score[0] - score[1]) >= marginToWin) {
            return true
        } else {
            return false
        }
    }
    
    var winner: Player?
    var state: State = .playing
    
    var isOddGameConcluded: Bool {
        get {
            if games.count % 2 == 0 {
                return true
            } else {
                return false
            }
        }
    }
    
    var isSetPoint: Bool {
        get {
            if ((score[0] >= minimumToWin - 1) && (score[0] >= score[1] + 1) && (game.score[0] >= game.minimumToWin - 1) && (game.score[0] >= game.score[1] + 1)) {
                return true
            } else if ((score[1] >= minimumToWin - 1) && (score[1] >= score[0] + 1) && (game.score[1] >= game.minimumToWin - 1) && (game.score[1] >= game.score[0] + 1)) {
                return true
            } else {
                return false
            }
        }
    }
    
    init() {
        games.append(game)
    }
    
    // Methods
    func scorePoint(for player: Player) {
        switch player {
        case .player1:
            score[0] += 1
        case .player2:
            score[1] += 1
        }
        
        if isWinConditionMet {
            winner = player
            state = .finished
        }
    }
    
    func getScore(for player: Player) -> String {
        switch player {
        case .player1:
            return String(self.score[0])
        case .player2:
            return String(self.score[1])
        }
    }
}

// MARK: Match
class Match {
    // Properties
    var score = [0, 0]
    
    var set = Set()
    var sets = [Set]() {
        didSet {
            set = sets.last!
            
            switch oldValue.last?.games.last?.servicePlayer {
            case .player1?:
                set.game.servicePlayer = .player2
            case .player2?:
                set.game.servicePlayer = .player1
            default:
                break
            }
        }
    }
    
    var isWinConditionMet: Bool {
        if score[0] >= 3 || score[1] >= 3 {
            return true
        } else {
            return false
        }
    }
    
    var winner: Player?
    var state: State = .playing
    
    var oldMatch: Match?
    
    // Methods
    func scorePoint(for player: Player) {
        switch player {
        case .player1:
            score[0] += 1
        case .player2:
            score[1] += 1
        }
        
        if isWinConditionMet {
            winner = player
            state = .finished
        }
    }
    
    init() {
        sets.append(set)
        
        switch Bool.random() {
        case true:
            set.game.servicePlayer = .player1
        case false:
            set.game.servicePlayer = .player2
        }
    }
}

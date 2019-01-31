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
    case player1, player2
}

// MARK: Game
class Game {
    // Properties
    var score = [0, 0]
    
    var isDeuce: Bool {
        if (score[0] >= 3 || score[1] >= 3) && score[0] == score[1] {
            return true
        } else {
            return false
        }
    }
    
    var isWinConditionMet: Bool {
        if (score[0] >= 4 || score[1] >= 4) && (abs(score[0] - score[1]) >= 2) {
            return true
        } else {
            return false
        }
    }
    
    var winner: Player?
    var state: State = .playing
    
    var delegate: GameDelegate?
    
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
        
        let game = self
        delegate?.gameDidUpdate(game)
    }
}

protocol GameDelegate {
    mutating func gameDidUpdate(_ game: Game)
}

// MARK: Set
class Set: GameDelegate {
    var score = [0, 0]
    
    var game = Game()
    var games = [Game]()
    
    var isWinConditionMet: Bool {
        if (score[0] >= 6 || score[1] >= 6) && (abs(score[0] - score[1]) >= 2) {
            return true
        } else {
            return false
        }
    }
    
    var winner: Player?
    var state: State = .playing
    
    var delegate: SetDelegate?
    
    init() {
        game.delegate = self
    }
    
    func gameDidUpdate(_ game: Game) {
        if let winner = game.winner {
            switch winner {
            case .player1:
                self.score[0] += 1
            case .player2:
                self.score[1] += 1
            }
            
            games.append(game)
            self.game = Game()
            self.game.delegate = self
        }
        
        delegate?.setDidUpdate(self)
    }
}

protocol SetDelegate {
    func setDidUpdate(_ set: Set)
}

// MARK: Match
class Match: SetDelegate {
    // Properties
    var score = [0, 0]
    
    var set = Set()
    var sets = [Set]()
    
    var isWinConditionMet: Bool {
        if score[0] >= 3 || score[1] >= 3 {
            return true
        } else {
            return false
        }
    }
    
    var winner: Player?
    
    var delegate: MatchDelegate?
    
    init() {
        set.delegate = self
    }
    
    func setDidUpdate(_ set: Set) {
        delegate?.matchDidUpdate(self)
    }
}

protocol MatchDelegate {
    func matchDidUpdate(_ match: Match)
}

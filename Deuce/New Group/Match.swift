//
//  Match.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation

enum MatchState {
    case notStarted
    case playing
    case finished
}

enum Player {
    case playerOne
    case playerTwo
}

enum Court {
    case deuceCourt
    case adCourt
}

enum SetType {
    case tiebreak
    case superTiebreak
    case advantage
}

struct Match {
    // MARK: Properties
    var score = [0, 0]
    
    var set = Set()
    
    var sets = [Set]() {
        didSet {
            set = Set()
            
            var lastServicePlayer: Player
            
            if let tiebreakStartingServicePlayer = sets.last!.games.last!.tiebreakStartingServicePlayer {
                lastServicePlayer = tiebreakStartingServicePlayer
            } else {
                lastServicePlayer = sets.last!.games.last!.servicePlayer!
            }
            
            switch lastServicePlayer {
            case .playerOne:
                set.game.servicePlayer = .playerTwo
            case .playerTwo:
                set.game.servicePlayer = .playerOne
            }
        }
    }
    
    var minimumToWin = 3
    
    var winner: Player? {
        get {
            if score[0] >= minimumToWin {
                return .playerOne
            } else if score[1] >= minimumToWin {
                return .playerTwo
            } else {
                return nil
            }
        }
    }
    
    var state: MatchState = .notStarted
    
    // MARK: Methods
    mutating func scorePoint(for player: Player) {
        state = .playing
        
        switch player {
        case .playerOne:
            set.game.score[0] += 1
        case .playerTwo:
            set.game.score[1] += 1
        }
        
        if set.game.isDeuce {
            set.game.score[0] = 3
            set.game.score[1] = 3
        }
        
        if let gameWinner = set.game.winner {
            switch gameWinner {
            case .playerOne:
                set.score[0] += 1
            case .playerTwo:
                set.score[1] += 1
            }
            
            set.games.append(set.game)
        }
        
        if let setWinner = set.winner {
            switch setWinner {
            case .playerOne:
                score[0] += 1
            case .playerTwo:
                score[1] += 1
            }
            
            sets.append(set)
        }
    }
    
    init() {
        switch Bool.random() {
        case true:
            set.game.servicePlayer = .playerOne
        case false:
            set.game.servicePlayer = .playerTwo
        }
    }
}

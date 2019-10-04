//
//  Match.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation

enum MatchState: String, Codable {
    case notStarted
    case playing
    case finished
}

enum Player: String, Codable {
    case playerOne
    case playerTwo
}

enum Court: String, Codable {
    case deuceCourt
    case adCourt
}

enum SetType: String, Codable {
    case tiebreak
    case superTiebreak
    case advantage
}


enum RulesFormats: String, Codable {
    case main = "Main"
    case alternate = "Alternate"
    case noAd = "No-Ad"
}

struct Stack<Element: Codable>: Codable {
    var items = [Element]()
    
    mutating func push(_ item: Element) {
        items.append(item)
    }
    
    mutating func pop() {
        items.removeLast()
    }
    
    var topItem: Element? {
        return items.isEmpty ? nil : items[items.count - 1]
    }
}

struct Match: Codable {
    
    // MARK: Properties
    var score = [0, 0] {
        didSet {
            if score[0] >= numberOfSetsToWin { winner = .playerOne }
            if score[1] >= numberOfSetsToWin { winner = .playerTwo }
        }
    }
    
    var set = SetManager()
    
    var sets = [SetManager]() {
        didSet {
            set = SetManager()
            
            var lastServicePlayer: Player?
            
            if let tiebreakStartingServicePlayer = sets.last?.games.last?.tiebreakStartingServicePlayer {
                lastServicePlayer = tiebreakStartingServicePlayer
            } else if let servicePlayer = sets.last?.games.last?.servicePlayer {
                lastServicePlayer = servicePlayer
            }
            
            switch lastServicePlayer {
            case .playerOne?:
                set.game.servicePlayer = .playerTwo
            case .playerTwo?:
                set.game.servicePlayer = .playerOne
            case .none:
                break
            }
            
            if (rulesFormat == .alternate || rulesFormat == .noAd) && score == [1, 1] {
                set.isSupertiebreak = true
            }
        }
    }
    
    /// Number of sets required to win the match. In a best-of 3 set series, the first to win 2 sets wins the match. In a best-of 5 it's 3 sets, and in a 1 set match it's of course 1 set.
    var numberOfSetsToWin = 2
    
    var winner: Player? {
        didSet {
            set.winner = winner
        }
    }
    
    var state: MatchState = .notStarted {
        didSet {
            switch state {
            case .playing:
                let userDefaults = UserDefaults()
                if let rulesFormatValue = userDefaults.string(forKey: "Rules Format") {
                    rulesFormat = RulesFormats(rawValue: rulesFormatValue)!
                }
                
                if rulesFormat == .noAd && !set.game.isTiebreak {
                    set.game.marginToWin = 1
                }
            case .finished:
                break
            default:
                break
            }
        }
    }
    
    var rulesFormat = RulesFormats.main
    
    var date: Date!
    var gamesCount = 0
    
    var isChangeover: Bool {
        get {
            // Changeovers happen during the tiebreak or superbreak.
            if (set.game.isTiebreak || set.isSupertiebreak) && set.game.score != [0, 0] {
                if (set.game.score[0] + set.game.score[1]) % 6 == 0 {
                    return true
                } else {
                    return false
                }
            } else {
                // Changeovers happen between games rather than during the game.
                if (set.games.count % 2 == 1) && set.game.score == [0, 0] {
                    return true
                } else {
                    // Check the games count of the set that was just finished and appended.
                    if set.score == [0, 0] {
                        if (((sets.last?.games.count) ?? 0) % 2 == 1) && set.game.score == [0, 0] {
                            return true
                        } else {
                            return false
                        }
                    } else {
                        return false
                    }
                }
            }
        }
    }
    
    // MARK: - Methods
    
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
        
        // TODO: Simplify game winner and set winner logic to make it consistent with match winner implementation.
        if let gameWinner = set.game.winner {
            switch gameWinner {
            case .playerOne:
                set.score[0] += 1
            case .playerTwo:
                set.score[1] += 1
            }
            
            set.games.append(set.game)
            
            if set.isSupertiebreak {
                winner = gameWinner
            }
            
            gamesCount += 1
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
        
        if winner != nil {
            // FIXME: Reduce dependencies related to sets count.
            if set.isSupertiebreak {
                sets.append(set)
            }
            state = .finished
        }
    }
    
    /// Either player is one point away from winning the match.
    func isMatchPoint() -> Bool {
        if set.isSetPoint() {
            if (score[0] + 1 == numberOfSetsToWin) && (set.game.playerWithGamePoint() == .playerOne) {
                return true
            }
            
            if (score[1] + 1 == numberOfSetsToWin) && (set.game.playerWithGamePoint() == .playerTwo) {
                return true
            }
        }
        
        return false
    }
    
    mutating func stop() {
        if set.score != [0, 0] {
            sets.append(set)
        }
        
        date = Date()
    }
}

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
        items.isEmpty ? nil : items[items.count - 1]
    }
}

struct Match: Codable {
    
    // MARK: - Properties
    var playerOneName: String?
    var playerTwoName: String?
    
    var score = [0, 0] {
        didSet {
            if score[0] >= numberOfSetsToWin { winner = .playerOne }
            if score[1] >= numberOfSetsToWin { winner = .playerTwo }
        }
    }
    
    var set = Set()
    
    var sets: [Set] {
        didSet {
            set = Set()
            
            var lastServicePlayer: Player?
            
            if let tiebreakStartingServicePlayer = sets.last?.games.last?.tiebreakStartingServicePlayer {
                lastServicePlayer = tiebreakStartingServicePlayer
            } else if let servicePlayer = sets.last?.games.last?.servicePlayer {
                lastServicePlayer = servicePlayer
            }
            
            switch lastServicePlayer {
            case .playerOne:
                set.game.servicePlayer = .playerTwo
            case .playerTwo:
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
    
    var state: MatchState = .playing {
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
    
    var currentGame: Game {
        get { sets.last!.games.last! }
        set { currentSet.games[currentSet.games.count - 1] = newValue }
    }
    
    var currentSet: Set {
        get { sets.last! }
        set { sets[sets.count - 1] = newValue }
    }
    
    init() {
        sets = [set]
    }
    
    // MARK: - Methods
    
    mutating func scorePoint(for player: Player) {
        switch player {
        case .playerOne:
            currentGame.score[0] += 1
        case .playerTwo:
            currentGame.score[1] += 1
        }
        
        if currentGame.isDeuce {
            currentGame.score[0] = 3
            currentGame.score[1] = 3
        }
        
        checkWonGame()
    }
    
    private mutating func checkWonGame() {
        if let gameWinner = currentGame.winner {
            switch gameWinner {
            case .playerOne:
                currentSet.score[0] += 1
            case .playerTwo:
                currentSet.score[1] += 1
            }
            
            currentSet.games.append(Game())
            
            if currentSet.isSupertiebreak {
                winner = gameWinner
            }
            
            gamesCount += 1
            
            checkWonSet()
        }
    }
    
    private mutating func checkWonSet() {
        if let setWinner = currentSet.winner {
            switch setWinner {
            case .playerOne:
                score[0] += 1
            case .playerTwo:
                score[1] += 1
            }
            
            checkWonMatch()
        }
    }
    
    private mutating func checkWonMatch() {
        if self.winner == nil {
            sets.append(Set())
        } else {
            if currentSet.isSupertiebreak {
                sets.append(Set())
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
        
        /// No-ad format.
        if set.game.marginToWin == 1 {
            if (score[0] + 1 == numberOfSetsToWin) && (set.game.playerWithGamePoint() == .playerOne) {
                return true
            }
            
            if (score[1] + 1 == numberOfSetsToWin) && (set.game.playerWithGamePoint() == .playerTwo) {
                return true
            }
        }
        
        return false
    }
    
    func playerWithMatchPoint() -> Player? {
        if set.isSetPoint() {
            if (score[0] + 1 == numberOfSetsToWin) && (set.game.playerWithGamePoint() == .playerOne) {
                return .playerOne
            }
            
            if (score[1] + 1 == numberOfSetsToWin) && (set.game.playerWithGamePoint() == .playerTwo) {
                return .playerTwo
            }
        }
        
        return nil
    }
    
    mutating func stop() {
        if set.score != [0, 0] {
            sets.append(set)
        }
        
        date = Date()
    }
}

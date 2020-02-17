//
//  Match.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Match: Codable {
    // MARK: - Properties
    var playerOneName: String?
    var playerTwoName: String?
    
    var servicePlayer: Player! = .playerOne
    
    var setsWon = [0, 0] {
        didSet {
            if setsWon[0] >= numberOfSetsToWin { winner = .playerOne }
            if setsWon[1] >= numberOfSetsToWin { winner = .playerTwo }
        }
    }
    
    var set = Set()
    
    var sets: [Set]
    
    /// Number of sets required to win the match. In a best-of 3 set series, the first to win 2 sets wins the match. In a best-of 5 it's 3 sets, and in a 1 set match it's of course 1 set.
    var numberOfSetsToWin = 2
    
    var winner: Player?
    
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
            if set.game.isTiebreak && set.game.pointsWon != [0, 0] {
                if (set.game.pointsWon[0] + set.game.pointsWon[1]) % 6 == 0 {
                    return true
                } else {
                    return false
                }
            } else {
                // Changeovers happen between games rather than during the game.
                if (set.games.count % 2 == 1) && set.game.pointsWon == [0, 0] {
                    return true
                } else {
                    // Check the games count of the set that was just finished and appended.
                    if set.gamesWon == [0, 0] {
                        if (((sets.last?.games.count) ?? 0) % 2 == 1) && set.game.pointsWon == [0, 0] {
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
            currentSet.currentGame.pointsWon[0] += 1
        case .playerTwo:
            currentSet.currentGame.pointsWon[1] += 1
        }
        
        if currentSet.currentGame.isDeuce {
            currentSet.currentGame.pointsWon[0] = 3
            currentSet.currentGame.pointsWon[1] = 3
        }
        
        checkWonGame()
        updateService()
    }
    
    private mutating func checkWonGame() {
        if let gameWinner = currentSet.currentGame.winner {
            switch gameWinner {
            case .playerOne:
                currentSet.gamesWon[0] += 1
            case .playerTwo:
                currentSet.gamesWon[1] += 1
            }
            
            checkWonSet()
        }
    }
    
    private mutating func checkWonSet() {
        if let setWinner = currentSet.winner {
            switch setWinner {
            case .playerOne:
                self.setsWon[0] += 1
            case .playerTwo:
                self.setsWon[1] += 1
            }
            
            checkWonMatch()
        }
    }
    
    private mutating func checkWonMatch() {
        if self.winner == nil {
            sets.append(Set())
        } else {
            self.state = .finished
        }
    }
    
    mutating func stop() {
        if set.gamesWon != [0, 0] {
            sets.append(set)
        }
        
        date = Date()
    }
    
    /// Updates the state of the service player and side of the court which they are serving on.
    private mutating func updateService() {
        if currentSet.currentGame.pointsWon == [0, 0] {
            switchServicePlayer()
        } else {
            if currentSet.currentGame.isTiebreak && currentSet.currentGame.pointsWon.sum.isOdd {
                switchServicePlayer()
                currentSet.currentGame.serviceSide = .adCourt
            } else {
                switchServiceCourt()
            }
        }
    }
    
    private mutating func switchServiceCourt() {
        switch currentSet.currentGame.serviceSide {
        case .deuceCourt:
            currentSet.currentGame.serviceSide = .adCourt
        case .adCourt:
            currentSet.currentGame.serviceSide = .deuceCourt
        }
    }
    
    private mutating func switchServicePlayer() {
        switch servicePlayer! {
        case .playerOne:
            servicePlayer = .playerTwo
        case .playerTwo:
            servicePlayer = .playerOne
        }
    }
    
    /// Receiving player is one point away from winning the game.
    func isBreakPoint() -> Bool {
        switch servicePlayer! {
        case .playerOne:
            if setsWon[1] >= currentSet.currentGame.numberOfPointsToWin - 1 && setsWon[1] > setsWon[0] && !currentSet.currentGame.isTiebreak {
                return true
            }
        case .playerTwo:
            if setsWon[0] >= currentSet.currentGame.numberOfPointsToWin - 1 && setsWon[0] > setsWon[1] && !currentSet.currentGame.isTiebreak {
                return true
            }
        }
        
        return false
    }
}

extension Match {
    enum CodingKeys: String, CodingKey {
        case setsWon = "score"
        case sets
        case date
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        setsWon = try values.decode(Array.self, forKey: .setsWon)
        sets = try values.decode(Array.self, forKey: .sets)
        date = try values.decode(Date.self, forKey: .date)
    }
}

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

extension Int {
    var isEven: Bool  { self % 2 == 0 }
    var isOdd: Bool { !isEven }
}

extension Array where Element == Int {
    var sum: Int { return self.reduce(0, +) }
}

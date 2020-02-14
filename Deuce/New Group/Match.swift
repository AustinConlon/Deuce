//
//  Match.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
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

extension Int {
    var isEven: Bool  { self % 2 == 0 }
    var isOdd: Bool { self % 1 == 0 }
}

extension Array where Element == Int {
    var sum: Int { return self.reduce(0, +) }
}



struct Match: Codable {
    
    // MARK: - Properties
    var playerOneName: String?
    var playerTwoName: String?
    
    var servicePlayer: Player! = .playerOne
    
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
    
    var currentGame: Set.Game {
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
        updateService()
    }
    
    private mutating func checkWonGame() {
        if let gameWinner = currentGame.winner {
            switch gameWinner {
            case .playerOne:
                currentSet.score[0] += 1
            case .playerTwo:
                currentSet.score[1] += 1
            }
            
            currentSet.games.append(Set.Game())
            
            if currentSet.isSupertiebreak {
                winner = gameWinner
            }
            
            checkWonSet()
        }
    }
    
    private mutating func checkWonSet() {
        if let setWinner = currentSet.winner {
            switch setWinner {
            case .playerOne:
                self.score[0] += 1
            case .playerTwo:
                self.score[1] += 1
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
            self.state = .finished
        }
    }
    
    mutating func stop() {
        if set.score != [0, 0] {
            sets.append(set)
        }
        
        date = Date()
    }
    
    /// Updates the state of the service player and side of the court which they are serving on.
    private mutating func updateService() {
        switch currentGame.isTiebreak {
        case true:
            if currentGame.pointsPlayed.isOdd {
                currentGame.serviceSide = .adCourt
                
                switch servicePlayer! {
                case .playerOne:
                    servicePlayer = .playerTwo
                case .playerTwo:
                    servicePlayer = .playerOne
                }
            } else {
                switch currentGame.serviceSide {
                case .deuceCourt:
                    currentGame.serviceSide = .adCourt
                case .adCourt:
                    currentGame.serviceSide = .deuceCourt
                }
            }
        case false:
            if currentGame.score == [0, 0] {
                switchServicePlayer()
            } else {
                switchServiceCourt()
            }
        }
    }
    
    private mutating func switchServiceCourt() {
        switch currentGame.serviceSide {
        case .deuceCourt:
            currentGame.serviceSide = .adCourt
        case .adCourt:
            currentGame.serviceSide = .deuceCourt
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
            if score[1] >= currentGame.numberOfPointsToWin - 1 && score[1] > score[0] && !currentGame.isTiebreak {
                return true
            }
        case .playerTwo:
            if score[0] >= currentGame.numberOfPointsToWin - 1 && score[0] > score[1] && !currentGame.isTiebreak {
                return true
            }
        }
        
        return false
    }
    
    struct Set: Codable, Hashable {
        var score = [0, 0] {
            didSet {
                if self.score == [6, 6] && score == [1, 1] {
                    
                }
            }
        }
        
        var game = Game()
        
        var games: [Game]
        
        static var setType: SetType = .tiebreak
        
        /// Number of games required to win the set. This is typically 6 games, but in a supertiebreak format it's 1 supertiebreakgame that replaces the 3rd set when it's tied 1 set to 1.
        var numberOfGamesToWin = 6
        
        var marginToWin: Int {
            get {
                if Set.setType == .tiebreak && (score == [7, 6] || score == [6, 7]) {
                    return 1
                } else {
                    return 2
                }
            }
        }
        
        var winner: Player?
        
        /// In an alternate match format when it's tied 1 set to 1, a 10 point "supertiebreak" game is played instead of a third set.
        var isSupertiebreak = false {
            didSet {
                if isSupertiebreak {
                    numberOfGamesToWin = 1
                    game.isTiebreak = true
                    game.numberOfPointsToWin = 10
                }
            }
        }
        
        init() {
            games = [game]
        }
        
        // MARK: Methods
        
        func getScore(for player: Player) -> String {
            switch player {
            case .playerOne:
                return String(self.score[0])
            case .playerTwo:
                return String(self.score[1])
            }
        }
        
        struct Game: Codable, Hashable {
            // MARK: - Properties
            
            var serviceSide: Court = .deuceCourt
            var tiebreakStartingServicePlayer: Player?
            
            var score = [0, 0]
            
            static var pointNames = [
                0: "Love", 1: "15", 2: "30", 3: "40", 4: "Ad"
            ]
            
            var isDeuce: Bool {
                if (score[0] >= 3 || score[1] >= 3) && score[0] == score[1] && !isTiebreak {
                    return true
                } else {
                    return false
                }
            }
            
            var numberOfPointsToWin = 4
            var marginToWin = 2
            
            var winner: Player? {
                get {
                    if (score[0] >= numberOfPointsToWin) && score[0] >= (score[1] + marginToWin) {
                        return .playerOne
                    } else if (score[1] >= numberOfPointsToWin) && score[1] >= (score[0] + marginToWin) {
                        return .playerTwo
                    } else {
                        return nil
                    }
                }
            }
            
            var isTiebreak = false {
                didSet {
                    if isTiebreak == true {
                        if Match.Set.setType == .tiebreak {
                            numberOfPointsToWin = 7
                        }
                    }
                }
            }
            
            var pointsPlayed: Int { score.sum }
            
            // MARK: - Methods
            
            func score(for player: Player) -> String {
                switch (player, isTiebreak) {
                case (.playerOne, false):
                    return Game.pointNames[score[0]]!
                case (.playerTwo, false):
                    return Game.pointNames[score[1]]!
                case (.playerOne, true):
                    return String(score[0])
                case (.playerTwo, true):
                    return String(score[1])
                }
            }
            
            /// Convienence method for `isSetPoint()` in a `Set`.
            func isGamePoint() -> Bool {
                if score[0] >= numberOfPointsToWin - 1 && score[0] > score[1] {
                    return true
                } else if score[1] >= numberOfPointsToWin - 1 && score[1] > score[0] {
                    return true
                } else {
                    return false
                }
            }
            
            func playerWithGamePoint() -> Player? {
                if score[0] >= (numberOfPointsToWin - 1) && score[0] > score[1] {
                    return .playerOne
                } else if score[1] >= (numberOfPointsToWin - 1) && score[1] > score[0] {
                    return .playerTwo
                } else {
                    return nil
                }
            }
            
            func advantage() -> Player? {
                if marginToWin == 2 {
                    if score == [4, 3] { return .playerOne }
                    if score == [3, 4] { return .playerTwo }
                }
                return nil
            }
        }
    }
}

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
            if winner == nil { sets.append(Set()) }
            if (format == .alternate || format == .noAd) && setsWon == [1, 1] {
                startSupertiebreak()
            }
        }
    }
    
    var sets: [Set]
    
    /// Number of sets required to win the match. In a best-of 3 set series, the first to win 2 sets wins the match. In a best-of 5 it's 3 sets, and in a 1 set match it's of course 1 set.
    var numberOfSetsToWin = 2
    
    var winner: Player?
    
    var state: MatchState = .playing
    
    var format: RulesFormats
    
    var date: Date!
    var gamesCount = 0
    
    var currentSet: Set {
        get { sets.last! }
        set { sets[sets.count - 1] = newValue }
    }
    
    var undoStack = Stack<Match>()
    
    init(format: Format) {
        self.format = RulesFormats(rawValue: format.name)!
        if self.format == .noAd { Game.noAd = true }
        sets = [Set()]
    }
    
    // MARK: - Methods
    
    mutating func scorePoint(for player: Player) {
        undoStack.push(self)
        
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
        if self.winner != nil {
            self.state = .finished
        }
    }
    
    mutating func stop() {
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
    
    mutating func startSupertiebreak() {
        currentSet.currentGame.isTiebreak = true
        currentSet.currentGame.numberOfPointsToWin = 10
        currentSet.numberOfGamesToWin = 1
        currentSet.marginToWin = 1
    }
    
    mutating func undo() {
        if let previousMatch = undoStack.topItem {
            self = previousMatch
        }
    }
}

extension Match {
    enum CodingKeys: String, CodingKey {
        case setsWon = "score"
        case sets
        case date
        case format = "rulesFormat"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        setsWon = try values.decode(Array.self, forKey: .setsWon)
        sets = try values.decode(Array.self, forKey: .sets)
        date = try values.decode(Date.self, forKey: .date)
        format = try values.decode(RulesFormats.self, forKey: .format)
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

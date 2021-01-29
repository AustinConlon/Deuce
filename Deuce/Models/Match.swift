//
//  Match.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Match: Codable {
    var format: RulesFormats
    
    var playerOneName: String?
    var playerTwoName: String?
    
    var servicePlayer: Player! {
        didSet {
            currentSet.currentGame.currentPoint.servicePlayer = servicePlayer
        }
    }
    
    var setsWon = [0, 0] {
        didSet {
            if self.winner == nil { sets.append(Set(format: format)) }
            if (format == .alternate || format == .noAd) && setsWon == [1, 1] {
                startSupertiebreak()
            }
        }
    }
    
    var setsPlayed: Int { setsWon.sum }
    
    var sets: [Set]
    /// Number of sets required to win the match. In a best-of 3 set series, the first to win 2 sets wins the match. In a best-of 5 it's 3 sets, and in a 1 set match it's of course 1 set.
    var numberOfSetsToWin: Int
    
    var winner: Team? {
        get {
            if setsWon[0] >= numberOfSetsToWin { return .teamOne }
            if setsWon[1] >= numberOfSetsToWin { return .teamTwo }
            return nil
        }
    }
    
    var state: MatchState = .playing
    var date: Date!
    
    var currentSet: Set {
        get { sets.last! }
        set { sets[sets.count - 1] = newValue }
    }
    
    var undoStack = Stack<Match>()
    
    var totalGamesPlayed: Int {
        var totalGamesPlayed = 0
        for set in sets { totalGamesPlayed += set.gamesPlayed }
        return totalGamesPlayed
    }
    
    var isSupertiebreak: Bool {
        switch format {
        case .alternate, .noAd:
            if setsWon == [1, 1] { return true }
        default:
            return false
        }
        return false
    }
    
    var playerOneServicePointsPlayed: Int!
    var playerTwoServicePointsPlayed: Int!
    
    var playerOneServicePointsWon: Int!
    var playerTwoServicePointsWon: Int!
    
    var teamOneBreakPointsPlayed: Int!
    var teamTwoBreakPointsPlayed: Int!
    
    var teamOneBreakPointsWon: Int!
    var teamTwoBreakPointsWon: Int!
    
    var allPointsPlayed: [Point] {
        get {
            var allPointsPlayed = [Point]()
            for set in sets {
                for game in set.games {
                    for point in game.points where point.winner != nil {
                        allPointsPlayed.append(point)
                    }
                }
            }
            return allPointsPlayed
        }
    }
    
    var teamOnePointsWon: Int {
        var teamOnePointsWon = 0
        
        for point in allPointsPlayed {
            if point.winner == .teamOne {
                teamOnePointsWon += 1
            }
        }
        return teamOnePointsWon
    }
    
    var teamTwoPointsWon: Int {
        var teamTwoPointsWon = 0
        for point in allPointsPlayed {
            if point.winner == .teamTwo {
                teamTwoPointsWon += 1
            }
        }
        return teamTwoPointsWon
    }
    
    var notes = "Notes"
    
    var isDoubles: Bool
    
    var isSingles: Bool {
        get {
            !isDoubles
        }
        set {
            isDoubles = !newValue
        }
    }
    
    /// In doubles, the returning team chooses who returns serve at the start of the second game of each set, and the pattern continues for the remainder of the set.
    var isSelectingReturningPlayer = false
    
    // MARK: - Initialization
    init(format: Format) {
        self.format = RulesFormats(rawValue: format.name)!
        if self.format == .noAd {
            Game.noAd = true
        } else {
            Game.noAd = false
        }
        self.numberOfSetsToWin = format.minimumSetsToWinMatch
        self.sets = [Set(format: self.format)]
        
        self.playerOneServicePointsPlayed = 0
        self.playerTwoServicePointsPlayed = 0
        
        self.playerOneServicePointsWon = 0
        self.playerTwoServicePointsWon = 0
        
        self.teamOneBreakPointsPlayed = 0
        self.teamTwoBreakPointsPlayed = 0
        
        self.teamOneBreakPointsWon = 0
        self.teamTwoBreakPointsWon = 0
        
        self.isDoubles = format.isDoubles
    }
    
    mutating func scorePoint(for team: Team) {
        undoStack.push(self)
        
        switch team {
        case .teamOne:
            currentSet.currentGame.pointsWon[0] += 1
        case .teamTwo:
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
            case .teamOne:
                currentSet.gamesWon[0] += 1
            case .teamTwo:
                currentSet.gamesWon[1] += 1
            }
            
            checkWonSet()
        }
    }
    
    private mutating func checkWonSet() {
        if let setWinner = currentSet.winner {
            switch setWinner {
            case .teamOne:
                self.setsWon[0] += 1
            case .teamTwo:
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
        calculateStatistics()
    }
    
    /// Updates the state of the service player and side of the court which they are serving on.
    private mutating func updateService() {
        if currentSet.currentGame.pointsWon == [0, 0] {
            updateServicePlayer()
        } else {
            if currentSet.currentGame.isTiebreak && currentSet.currentGame.pointsWon.sum.isOdd {
                updateServicePlayer()
                currentSet.currentGame.serviceSide = .adCourt
            } else {
                toggleServiceCourt()
            }
        }
    }
    
    private mutating func toggleServiceCourt() {
        switch currentSet.currentGame.serviceSide {
        case .deuceCourt:
            currentSet.currentGame.serviceSide = .adCourt
        case .adCourt:
            currentSet.currentGame.serviceSide = .deuceCourt
        }
    }
    
    private mutating func updateServicePlayer() {
        switch (isDoubles, servicePlayer) {
        case (true, .playerOne):
            servicePlayer = .playerTwo
        case (true, .playerThree):
            servicePlayer = .playerFour
        case (true, .playerTwo):
            servicePlayer = .playerOne
        case (true, .playerFour):
            servicePlayer = .playerThree
        case (false, .playerOne):
            servicePlayer = .playerTwo
        case (false, .playerTwo):
            servicePlayer = .playerOne
        default:
            break
        }
        
        if self.isDoubles && currentSet.gamesPlayed == 1 && currentSet.currentGame.pointsWon == [0, 0] {
            servicePlayer = nil
        }
    }
    
    mutating func startSupertiebreak() {
        currentSet.currentGame.isTiebreak = true
        currentSet.currentGame.numberOfPointsToWin = 10
        currentSet.numberOfGamesToWin = 1
        currentSet.marginToWin = 1
    }
    
    func isChangeover() -> Bool {
        if currentSet.currentGame.isTiebreak && (currentSet.currentGame.pointsPlayed % 6 == 0) && currentSet.currentGame.pointsPlayed > 0 {
            return true
        } else if setsPlayed >= 1 &&
                  currentSet.gamesPlayed == 0 &&
                  currentSet.currentGame.pointsPlayed == 0 {
            if sets[setsPlayed - 1].gamesPlayed.isOdd {
                return true
            }
        } else if currentSet.currentGame.pointsPlayed == 0 {
            return currentSet.gamesPlayed.isOdd
        }
        return false
    }
    
    func teamWithMatchPoint() -> Team? {
        if let teamWithSetPoint = currentSet.teamWithSetPoint() {
            switch teamWithSetPoint {
            case .teamOne:
                if self.setsWon[0] == numberOfSetsToWin - 1 {
                    return .teamOne
                }
            case .teamTwo:
                if self.setsWon[1] == numberOfSetsToWin - 1 {
                    return .teamTwo
                }
            }
        }
        return nil
    }
    
    func isMatchPoint() -> Bool {
        teamWithMatchPoint() != nil ? true : false
    }
    
    mutating func undo() {
        if let previousMatch = undoStack.topItem {
            self = previousMatch
        }
    }
    
    // MARK: - Statistics
    
    func totalGamesWon(by team: Team) -> Int {
        var totalGamesWon = 0
        for set in sets {
            switch team {
            case .teamOne:
                totalGamesWon += set.gamesWon[0]
            case .teamTwo:
                totalGamesWon += set.gamesWon[1]
            }
        }
        return totalGamesWon
    }
    
    private mutating func calculateStatistics() {
        calculateServicePointsWon()
        calculateServicePointsPlayed()
        calculateBreakPointsWon()
        calculateBreakPointsPlayed()
    }
    
    private mutating func calculateServicePointsWon() {
        for point in allPointsPlayed {
            switch (point.serviceTeam, point.winner) {
            case (.teamOne, .teamOne):
                self.playerOneServicePointsWon += 1
            case (.teamTwo, .teamTwo):
                self.playerTwoServicePointsWon += 1
            default:
                break
            }
        }
    }
    
    private mutating func calculateServicePointsPlayed() {
        for point in allPointsPlayed {
            switch point.servicePlayer {
            case .playerOne:
                playerOneServicePointsPlayed += 1
            case .playerTwo:
                playerTwoServicePointsPlayed += 1
            default:
                break
            }
        }
    }
    
    private mutating func calculateBreakPointsWon() {
        for point in allPointsPlayed where point.isBreakpoint {
            switch (point.winner, point.returningTeam) {
            case (.teamOne, .teamOne):
                teamOneBreakPointsWon += 1
            case (.teamTwo, .teamTwo):
                teamTwoBreakPointsWon += 1
            default:
                break
            }
        }
    }
    
    private mutating func calculateBreakPointsPlayed() {
        for set in sets {
            for game in set.games {
                for point in game.points where point.isBreakpoint {
                    switch (point.returningTeam!, game.teamWithGamePoint()) {
                    case (.teamOne, .teamOne):
                        teamOneBreakPointsPlayed += 1
                    case (.teamTwo, .teamTwo):
                        teamTwoBreakPointsPlayed += 1
                    default:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - Decoding
extension Match {
    enum CodingKeys: String, CodingKey {
        case setsWon = "score"
        case sets
        case date
        case format = "rulesFormat"
        case numberOfSetsToWin
        case playerOneName
        case playerTwoName
        case playerOneServicePointsPlayed
        case playerTwoServicePointsPlayed
        case playerOneServicePointsWon
        case playerTwoServicePointsWon
        case teamOneBreakPointsPlayed
        case teamTwoBreakPointsPlayed
        case teamOneBreakPointsWon
        case teamTwoBreakPointsWon
        case notes
        case isDoubles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        setsWon = try container.decode(Array.self, forKey: .setsWon)
        sets = try container.decode(Array.self, forKey: .sets)
        date = try container.decode(Date.self, forKey: .date)
        format = try container.decode(RulesFormats.self, forKey: .format)
        numberOfSetsToWin = try container.decode(Int.self, forKey: .numberOfSetsToWin)
        playerOneName = try container.decodeIfPresent(String.self, forKey: .playerOneName)
        playerTwoName = try container.decodeIfPresent(String.self, forKey: .playerTwoName)
        playerOneServicePointsPlayed = try container.decodeIfPresent(Int.self, forKey: .playerOneServicePointsPlayed)
        playerTwoServicePointsPlayed = try container.decodeIfPresent(Int.self, forKey: .playerTwoServicePointsPlayed)
        playerOneServicePointsWon = try container.decodeIfPresent(Int.self, forKey: .playerOneServicePointsWon)
        playerTwoServicePointsWon = try container.decodeIfPresent(Int.self, forKey: .playerTwoServicePointsWon)
        teamOneBreakPointsPlayed = try container.decodeIfPresent(Int.self, forKey: .teamOneBreakPointsPlayed)
        teamTwoBreakPointsPlayed = try container.decodeIfPresent(Int.self, forKey: .teamTwoBreakPointsPlayed)
        teamOneBreakPointsWon = try container.decodeIfPresent(Int.self, forKey: .teamOneBreakPointsWon)
        teamTwoBreakPointsWon = try container.decodeIfPresent(Int.self, forKey: .teamTwoBreakPointsWon)
        notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? "Notes"
        isDoubles = try container.decode(Bool.self, forKey: .isDoubles)
    }
}

enum MatchState: String, Codable {
    case notStarted
    case playing
    case finished
}

/// Individual player for tracking service and statistics.
enum Player: String, Codable {
    /// The user.
    case playerOne
    /// The user's partner in doubles.
    case playerThree
    /// The opponent in singles.
    case playerTwo
    /// The opponent's partner in doubles.
    case playerFour
}

enum Team: String, Codable {
    /// The user's team.
    case teamOne
    /// The opposing team.
    case teamTwo
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

extension Match {
    /// Mock data.
    static func random() -> Match {
        var match = Match(format: formatData.randomElement()!)
        match.servicePlayer = .playerOne
        while match.state != .finished {
            switch Bool.random() {
            case true:
                match.scorePoint(for: .teamOne)
            case false:
                match.scorePoint(for: .teamTwo)
            }
        }
        match.stop()
        return match
    }
}

//
//  Game.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation

struct Game {
    // Properties
    var servicePlayer: Player?
    var serviceSide: Court = .deuceCourt
    var tiebreakStartingServicePlayer: Player?
    
    var score = [0, 0] {
        didSet {
            updateService()
        }
    }
    
    static var pointNames = [
        0: "Love", 1: "15", 2: "30", 3: "40", 4: "AD"
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
            if score[0] >= numberOfPointsToWin && score[0] >= score[1] + marginToWin {
                return .playerOne
            } else if score[1] >= numberOfPointsToWin && score[1] >= score[0] + marginToWin {
                return .playerTwo
            } else {
                return nil
            }
        }
    }
    var state: MatchState = .playing
    
    var isTiebreak = false {
        didSet {
            if isTiebreak == true {
                if Set.setType == .tiebreak {
                    numberOfPointsToWin = 7
                }
                
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
    
    var isPointAfterSwitchingEnds: Bool {
        get {
            if isTiebreak && (totalPointsPlayed % 6 == 0) {
                if isFirstPoint {
                    return false
                } else {
                    return true
                }
            } else {
                return false
            }
        }
    }
    
    var isFirstPoint: Bool {
        get {
            if score[0] + score[1] == 0 {
                return true
            } else {
                return false
            }
        }
    }
    
    var totalPointsPlayed: Int {
        get {
            return score[0] + score[1]
        }
    }
    
    init() {
        // FIXME: There's probably a better way for a game to get the results format rather than directly from UserDefaults.
        let userDefaults = UserDefaults()
        if let rulesFormatValue = userDefaults.string(forKey: "Rules Format") {
            let rulesFormat = RulesFormats(rawValue: rulesFormatValue)!
            if rulesFormat == .noAd {
                marginToWin = 1
            }
        }
    }
    
    func getScore(for player: Player) -> String {
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
    
    /// Updates the state of the service player and side of the court they are serving on.
    private mutating func updateService() {
        switch isTiebreak {
        case true:
            if isOddPointConcluded {
                serviceSide = .deuceCourt
                
                switch servicePlayer {
                case .playerOne?:
                    servicePlayer = .playerTwo
                case .playerTwo?:
                    servicePlayer = .playerOne
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
    
    /// Receiving player is one point away from winning the game.
    func isBreakPoint() -> Bool {
        switch servicePlayer {
        case .playerOne?:
            if score[1] >= numberOfPointsToWin - 1 && score[1] > score[0] && !isTiebreak {
                return true
            }
        case .playerTwo?:
            if score[0] >= numberOfPointsToWin - 1 && score[0] > score[1] && !isTiebreak {
                return true
            }
        case .none:
            break
        }
        
        return false
    }
    
    /// Convienence method for `isSetPoint()` in a `Set`.
    func isGamePoint() -> Bool {
        if score[0] >= numberOfPointsToWin - 1 && score[0] > score[1] {
            return true
        } else if score[0] >= numberOfPointsToWin - 1 && score[0] > score[1] {
            return true
        } else {
            return false
        }
    }
}

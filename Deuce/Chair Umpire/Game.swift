//
//  Game.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

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
                if Set.setType == .tiebreak {
                    numberOfPointsToWin = 7
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
            score[0] + score[1]
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

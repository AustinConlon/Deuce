//
//  Set.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation

struct Set: Codable, Hashable {
    var score = [0, 0] {
        didSet {
            if (score[0] >= numberOfGamesToWin) && (score[0] >= score[1] + marginToWin) {
                winner = .playerOne
            } else if (score[1] >= numberOfGamesToWin) && (score[1] >= score[0] + marginToWin) {
                winner = .playerTwo
            }
        }
    }
    
    var game = Game()
    
    var games = [Game]() {
        didSet {
            game = Game()
            
            let lastServicePlayer = games.last?.servicePlayer
            
            switch lastServicePlayer {
            case .playerOne:
                game.servicePlayer = .playerTwo
            case .playerTwo:
                game.servicePlayer = .playerOne
            case .none:
                break
            }
            
            if score == [6, 6] {
                game.isTiebreak = true
                game.tiebreakStartingServicePlayer = game.servicePlayer
            }
        }
    }
    
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
    
    var state: MatchState = .playing
    
    var isOddGameConcluded: Bool {
        get {
            if games.count % 2 == 1 {
                return true
            } else {
                return false
            }
        }
    }
    
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
    
    // MARK: Methods
    
    func getScore(for player: Player) -> String {
        switch player {
        case .playerOne:
            return String(self.score[0])
        case .playerTwo:
            return String(self.score[1])
        }
    }
    
    /// Either player is one point away from winning the set. In a tiebreak, a set point is simply whether or not it is game point.
    func isSetPoint() -> Bool {
        if game.isGamePoint() && playerWithSetPoint() == game.playerWithGamePoint() {
            switch game.isTiebreak {
            case true:
                return game.isGamePoint()
            case false:
                if score[0] >= numberOfGamesToWin - 1 && score[0] > score[1] {
                    return true
                } else if score[1] >= numberOfGamesToWin - 1 && score[1] > score[0] {
                    return true
                } else {
                    return false
                }
            }
        } else {
            /// No-ad format.
            if game.marginToWin == 1 {
                if score[0] >= numberOfGamesToWin - 1 && score[0] > score[1] {
                    return true
                } else if score[1] >= numberOfGamesToWin - 1 && score[1] > score[0] {
                    return true
                } else {
                    return false
                }
            }
            return false
        }
    }
    
    func playerWithSetPoint() -> Player? {
        switch game.isTiebreak {
        case true:
            return game.playerWithGamePoint()
        case false:
            if score[0] >= numberOfGamesToWin - 1 && score[0] >= score[1] {
                return .playerOne
            } else if score[1] >= numberOfGamesToWin - 1 && score[1] >= score[0] {
                return .playerTwo
            } else {
                return nil
            }
        }
    }
}

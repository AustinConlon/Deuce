//
//  Set.swift
//  Deuce
//
//  Created by Austin Conlon on 2/16/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Set: Codable, Hashable {
    var format: RulesFormats?
    
    var gamesWon = [0, 0] {
        didSet {
            if self.winner == nil {
                games.append(Game(format: format!))
            }
            
            if gamesWon == [6, 6] {
                currentGame.isTiebreak = true
                self.marginToWin = 1
            }
        }
    }
    
    var games: [Game]
    
    var currentGame: Game {
        get { games.last! }
        set { games[games.count - 1] = newValue }
    }
    
    static var setType: SetType = .tiebreak
    
    /// Number of games required to win the set. This is typically 6 games, but in a supertiebreak format it's 1 supertiebreakgame that replaces the 3rd set when it's tied 1 set to 1.
    var numberOfGamesToWin = 6
    
    var marginToWin = 2
    
    var winner: Team? {
        switch games.last?.isTiebreak {
        case true:
            return games.last?.winner
        case false:
            if gamesWon[0] >= numberOfGamesToWin && ((gamesWon[0] - gamesWon[1]) >= marginToWin) {
                return .teamOne
            }
            
            if gamesWon[1] >= numberOfGamesToWin && ((gamesWon[1] - gamesWon[0]) >= marginToWin) {
                return .teamTwo
            }
        default:
            return nil
        }
        
        return nil
    }
    
    var gamesPlayed: Int { gamesWon.sum }
    
    // MARK: - Initialization
    
    init(format: RulesFormats) {
        self.format = format
        games = [Game(format: format)]
    }
    
    func score(of team: Team) -> String {
        switch team {
        case .teamOne:
            return String(self.gamesWon[0])
        case .teamTwo:
            return String(self.gamesWon[1])
        }
    }
    
    func teamWithSetPoint() -> Team? {
        if let teamWithGamePoint = currentGame.teamWithGamePoint() {
            switch teamWithGamePoint {
            case .teamOne:
                if ((self.gamesWon[0] == numberOfGamesToWin - 1) && (self.gamesWon[0] > self.gamesWon[1])) || currentGame.isTiebreak {
                    return .teamOne
                }
            case .teamTwo:
                if ((self.gamesWon[1] == numberOfGamesToWin - 1) && (self.gamesWon[1] > self.gamesWon[0])) || currentGame.isTiebreak {
                    return .teamTwo
                }
            }
        }
        return nil
    }
    
    func isSetPoint() -> Bool {
        teamWithSetPoint() != nil ? true : false
    }
}

extension Set {
    enum CodingKeys: String, CodingKey {
        case gamesWon = "score"
        case games
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gamesWon = try values.decode(Array.self, forKey: .gamesWon)
        games = try values.decode(Array.self, forKey: .games)
    }
}

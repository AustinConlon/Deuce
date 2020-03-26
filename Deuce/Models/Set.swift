//
//  Set.swift
//  Deuce
//
//  Created by Austin Conlon on 2/16/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Set: Codable, Hashable {
    var format: RulesFormats
    
    var gamesWon = [0, 0] {
        didSet {
            games.append(Game(format: format))
            
            if gamesWon == [6, 6] {
                currentGame.isTiebreak = true
                marginToWin = 1
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
    
    var winner: Player? {
        if gamesWon[0] >= numberOfGamesToWin && ((gamesWon[0] - gamesWon[1]) >= marginToWin) {
            return .playerOne
        }
        
        if gamesWon[1] >= numberOfGamesToWin && ((gamesWon[1] - gamesWon[0]) >= marginToWin) {
            return .playerTwo
        }
        
        return nil
    }
    
    var gamesPlayed: Int { gamesWon.sum }
    
    // MARK: - Initialization
    
    init(format: RulesFormats) {
        self.format = format
        games = [Game(format: format)]
    }
    
    // MARK: - Methods
    
    func getScore(for player: Player) -> String {
        switch player {
        case .playerOne:
            return String(self.gamesWon[0])
        case .playerTwo:
            return String(self.gamesWon[1])
        }
    }
    
    func playerWithSetPoint() -> Player? {
        if let playerWithGamePoint = currentGame.playerWithGamePoint() {
            switch playerWithGamePoint {
            case .playerOne:
                if ((self.gamesWon[0] == numberOfGamesToWin - 1) && (self.gamesWon[0] > self.gamesWon[1])) || currentGame.isTiebreak {
                    return .playerOne
                }
            case .playerTwo:
                if ((self.gamesWon[1] == numberOfGamesToWin - 1) && (self.gamesWon[1] > self.gamesWon[0])) || currentGame.isTiebreak {
                    return .playerTwo
                }
            }
        }
        return nil
    }
    
    func isSetPoint() -> Bool {
        playerWithSetPoint() != nil ? true : false
    }
}

extension Set {
    enum CodingKeys: String, CodingKey {
        case gamesWon = "score"
        case games
        case format
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gamesWon = try values.decode(Array.self, forKey: .gamesWon)
        games = try values.decode(Array.self, forKey: .games)
        format = try values.decode(RulesFormats.self, forKey: .format)
    }
}

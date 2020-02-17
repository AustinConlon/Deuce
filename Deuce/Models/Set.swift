//
//  Set.swift
//  Deuce
//
//  Created by Austin Conlon on 2/16/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Set: Codable, Hashable {
    var gamesWon = [0, 0]
    
    var game = Game()
    
    var games: [Game]
    
    static var setType: SetType = .tiebreak
    
    /// Number of games required to win the set. This is typically 6 games, but in a supertiebreak format it's 1 supertiebreakgame that replaces the 3rd set when it's tied 1 set to 1.
    var numberOfGamesToWin = 6
    
    var marginToWin: Int {
        get {
            if Set.setType == .tiebreak && (gamesWon == [7, 6] || gamesWon == [6, 7]) {
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
            return String(self.gamesWon[0])
        case .playerTwo:
            return String(self.gamesWon[1])
        }
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

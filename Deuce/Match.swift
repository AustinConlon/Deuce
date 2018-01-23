//
//  Match.swift
//  Deuce
//
//  Created by Bijan Massoumi on 1/18/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation

class Match {
    var player: String
    var opponent: String
    var maxSets: Int
    var playerScores = [Int]()
    var opponentScores = [Int]()
    var date: String
    var inDeuce: Bool
    var isLive: Bool
    

    
    init(player: String, opponent: String, date:String, maxSets: Int, isLive: Bool) {
        // Initialize stored properties.
        if player.isEmpty {
            self.player = "player"
        } else {
            self.player = player
        }
        
        if opponent.isEmpty {
            self.opponent = "opponent"
        } else {
            self.opponent = opponent
        }
        
        self.date = date
        self.isLive = isLive
        self.inDeuce = false
        self.maxSets = maxSets
        self.playerScores.append(0)
        self.opponentScores.append(0)
        print(maxSets)
    }
    func nextGame() {
        if (playerScores.count == maxSets) {
            self.isLive = false
        } else {
            self.playerScores.append(0)
            self.opponentScores.append(0)
        }
    }
    
}

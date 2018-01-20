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
    
    var playerScores = [UInt8]()
    var opponentScores = [UInt8]()
    
    var date: String
    
    
    init(player: String, opponent: String, date:String) {
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
    }
    
}

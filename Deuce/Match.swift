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
    
    var playerNumGamesWon = 0
    var opponentNumGamesWon = 0
    
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
        self.playerScores.append(0)    //right most element of these two lists
        self.opponentScores.append(0)  // are the curr game score of a live set.
    }
    
    func nextGame(winner: String) {
        if winner == "player" {
            playerNumGamesWon += 1
        } else {
            opponentNumGamesWon += 1
        }
        
        if ( (playerNumGamesWon >= 6 || playerNumGamesWon >= 6) && abs(playerNumGamesWon - opponentNumGamesWon) >= 2) {
            nextSet()
        } else {
            let last = playerScores.count - 1
            playerScores[last] = 0
            opponentScores[last] = 0
        }
    }
    
    func nextSet() {
        print("next Set")
        print(" ")
        let last = playerScores.count - 1
        playerScores[last] = playerNumGamesWon
        opponentScores[last] = opponentNumGamesWon
        
        if (playerScores.count == (maxSets/2) + 1)  {
            self.isLive = false
        } else {
            playerNumGamesWon = 0
            opponentNumGamesWon = 0
            playerScores.append(0)
            opponentScores.append(0)
        }
    }
}

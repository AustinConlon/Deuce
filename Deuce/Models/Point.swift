//
//  Point.swift
//  Deuce
//
//  Created by Austin Conlon on 7/2/20.
//  Copyright © 2021 Austin Conlon. All rights reserved.
//

import Foundation

struct Point: Codable, Hashable {
    var winner: Team?
    
    // TODO: Consolidate service state in this structure.
    var servicePlayer: Player!
    
    var serviceTeam: Team! {
        switch servicePlayer {
        case .playerOne, .playerThree:
            return .teamOne
        case .playerTwo, .playerFour:
            return .teamTwo
        case .none:
            return nil
        }
    }
    
    /// Player returning serve is one point away from winning the game.
    var isBreakpoint = false
    
    var returningTeam: Team! {
        switch servicePlayer {
        case .playerOne, .playerThree:
            return .teamTwo
        case .playerTwo, .playerFour:
            return .teamOne
        default:
            return nil
        }
    }
}

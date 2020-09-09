//
//  Point.swift
//  Deuce
//
//  Created by Austin Conlon on 7/2/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Point: Codable, Hashable {
    var winner: Player?
    var servicePlayer: Player!
    
    /// Player returning serve is one point away from winning the game.
    var isBreakpoint = false
    
    var returningPlayer: Player! {
        switch servicePlayer {
        case .playerOne:
            return .playerTwo
        case .playerTwo:
            return .playerOne
        default:
            return nil
        }
    }
}

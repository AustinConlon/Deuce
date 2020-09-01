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
    var isBreakpoint = false
}

//
//  Player.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 1/29/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation

enum Player {
    case you, opponent
}

// Server always starts on the right side, alternates after every point.
enum ServingSide {
    case left, right
}

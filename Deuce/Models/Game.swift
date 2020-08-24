//
//  Game.swift
//  Deuce
//
//  Created by Austin Conlon on 2/16/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Game: Codable, Hashable {
    // MARK: - Properties
    var format: RulesFormats?
    
    var points = [Point()]
    var currentPoint: Point {
        get { points.last! }
        set { points[points.count - 1] = newValue }
    }
    
    var serviceSide: Court = .deuceCourt
    
    var pointsWon = [0, 0] {
        willSet {
            /// There is currently a Swift bug where you can't subscript a property in its `willSet`, so I use `first` instead.
            if newValue[0] > pointsWon.first! {
                currentPoint.winner = .playerOne
                points.append(Point())
            }
            if newValue[1] > pointsWon.last! {
                currentPoint.winner = .playerTwo
                points.append(Point())
            }
        }
    }
    
    static var pointNames = [
        0: "Love", 1: "15", 2: "30", 3: "40", 4: "Ad"
    ]
    
    var isDeuce: Bool {
        if (pointsWon[0] >= 3 || pointsWon[1] >= 3) && pointsWon[0] == pointsWon[1] && !isTiebreak {
            return true
        } else {
            return false
        }
    }
    
    var numberOfPointsToWin = 4
    var marginToWin = 2
    
    var winner: Player? {
        get {
            if self.pointsWon.contains(where: { $0 >= numberOfPointsToWin }) {
                if pointsWon[0] >= (pointsWon[1] + marginToWin) {
                    return .playerOne
                } else if pointsWon[1] >= (pointsWon[0] + marginToWin) {
                    return .playerTwo
                }
            }
            
            return nil
        }
    }
    
    var isTiebreak = false {
        didSet {
            if isTiebreak == true {
                numberOfPointsToWin = 7
                marginToWin = 2
            }
        }
    }
    
    var pointsPlayed: Int { pointsWon.sum }
    
    static var noAd = false
    
    // MARK: - Initialization
    
    init(format: RulesFormats) {
        self.format = format
        if format == .noAd {
            marginToWin = 1
        } else {
            marginToWin = 2
        }
    }
    
    // MARK: - Methods
    
    func score(for player: Player) -> String {
        switch (player, isTiebreak) {
        case (.playerOne, false):
            return Game.pointNames[pointsWon[0]]!
        case (.playerTwo, false):
            return Game.pointNames[pointsWon[1]]!
        case (.playerOne, true):
            return String(pointsWon[0])
        case (.playerTwo, true):
            return String(pointsWon[1])
        }
    }
    
    func playerWithGamePoint() -> Player? {
        if (pointsWon[0] >= numberOfPointsToWin - 1) && (pointsWon[0] > pointsWon[1]) {
            return .playerOne
        }
        
        if (pointsWon[1] >= numberOfPointsToWin - 1) && (pointsWon[1] > pointsWon[0]) {
            return .playerTwo
        }
        
        return nil
    }
    
    func advantage() -> Player? {
        if marginToWin == 2 && !isTiebreak {
            if pointsWon == [4, 3] { return .playerOne }
            if pointsWon == [3, 4] { return .playerTwo }
        }
        return nil
    }
}

extension Game {
    enum CodingKeys: String, CodingKey {
        case pointsWon = "score"
    }
    
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pointsWon = try values.decode(Array.self, forKey: .pointsWon)
    }
}

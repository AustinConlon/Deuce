//
//  Game.swift
//  Deuce
//
//  Created by Austin Conlon on 1/21/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation

struct Game {
    // Properties
    var servicePlayer: Player?
    var serviceSide: Court = .deuceCourt
    var tiebreakStartingServicePlayer: Player?
    
    var score = [0, 0] {
        didSet {
            switch tiebreak {
            case true:
                if isOddPointConcluded {
                    serviceSide = .deuceCourt
                    
                    switch servicePlayer {
                    case .playerOne?:
                        servicePlayer = .playerTwo
                    case .playerTwo?:
                        servicePlayer = .playerOne
                    default:
                        break
                    }
                } else {
                    switch serviceSide {
                    case .deuceCourt:
                        serviceSide = .adCourt
                    case .adCourt:
                        serviceSide = .deuceCourt
                    }
                }
            case false:
                switch serviceSide {
                case .deuceCourt:
                    serviceSide = .adCourt
                case .adCourt:
                    serviceSide = .deuceCourt
                }
            }
        }
    }
    
    var servicePlayerScore: Int? {
        get {
            switch servicePlayer {
            case .playerOne?:
                return score[0]
            case .playerTwo?:
                return score[1]
            default:
                return 0
            }
        }
    }
    
    var receiverPlayerScore: Int? {
        get {
            switch servicePlayer {
            case .playerOne?:
                return score[1]
            case .playerTwo?:
                return score[0]
            default:
                return 0
            }
        }
    }
    
    static var pointNames = [
        0: "LOVE", 1: "15", 2: "30", 3: "40", 4: "AD"
    ]
    
    var isDeuce: Bool {
        if (score[0] >= 3 || score[1] >= 3) && score[0] == score[1] && !tiebreak {
            return true
        } else {
            return false
        }
    }
    
    var isBreakPoint: Bool {
        get {
            if let servicePlayerScore = servicePlayerScore, let receiverPlayerScore = receiverPlayerScore {
                if (receiverPlayerScore >= minimumToWin - 1) && (receiverPlayerScore >= servicePlayerScore + 1) && !tiebreak {
                    return true
                } else {
                    return false
                }
            } else {
                return false
            }
        }
    }
    
    var minimumToWin = 4
    var marginToWin = 2
    
    var winner: Player? {
        get {
            if score[0] >= minimumToWin && score[0] >= score[1] + marginToWin {
                return .playerOne
            } else if score[1] >= minimumToWin && score[1] >= score[0] + marginToWin {
                return .playerTwo
            } else {
                return nil
            }
        }
    }
    var state: MatchState = .playing
    
    var tiebreak = false {
        didSet {
            if tiebreak == true {
                if Set.setType == .tiebreak {
                    minimumToWin = 7
                } else if Set.setType == .superTiebreak {
                    minimumToWin = 10
                }
                
                if score == [0, 0] {
                    serviceSide = .adCourt
                }
            }
        }
    }
    
    var isOddPointConcluded: Bool {
        get {
            if (score[0] + score[1]) % 2 == 1 {
                return true
            } else {
                return false
            }
        }
    }
    
    func getScore(for player: Player) -> String {
        switch (player, tiebreak) {
        case (.playerOne, false):
            return Game.pointNames[score[0]]!
        case (.playerTwo, false):
            return Game.pointNames[score[1]]!
        case (.playerOne, true):
            return String(score[0])
        case (.playerTwo, true):
            return String(score[1])
        }
    }
}

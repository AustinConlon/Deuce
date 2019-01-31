//
//  Match.swift
//  Deuce
//
//  Created by Austin Conlon on 7/3/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import Foundation
import os.log

class MatchHistory: NSObject, NSCoding {
    // MARK: Properties
    var sets = [SetScore]()
    var matchWinner: String?
    
    // MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("matches")
    
    // MARK: Types
    
    struct PropertyKey {
        static let sets = "sets"
        static let matchWinner = "matchWinner"
    }
    
    // MARK: NSCoding
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(sets, forKey: PropertyKey.sets)
        aCoder.encode(matchWinner, forKey: PropertyKey.matchWinner)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let sets = aDecoder.decodeObject(forKey: PropertyKey.sets) as! [SetScore]
        let matchWinner = aDecoder.decodeObject(forKey: PropertyKey.matchWinner) as? String
        self.init()
        self.sets = sets
        self.matchWinner = matchWinner
    }
}

class SetScore: NSObject, NSCoding {
    var playerOneSetScore = 0
    var playerTwoSetScore = 0
    
    // MARK: Types
    struct PropertyKey {
        static let playerOneSetScore = "playerOneSetScore"
        static let playerTwoSetScore = "playerTwoSetScore"
    }
    
    // MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(playerOneSetScore, forKey: PropertyKey.playerOneSetScore)
        aCoder.encode(playerTwoSetScore, forKey: PropertyKey.playerTwoSetScore)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let playerOneSetScore = aDecoder.decodeInteger(forKey: PropertyKey.playerOneSetScore)
        let playerTwoSetScore = aDecoder.decodeInteger(forKey: PropertyKey.playerTwoSetScore)
        self.init()
        self.playerOneSetScore = playerOneSetScore
        self.playerTwoSetScore = playerTwoSetScore
    }
}

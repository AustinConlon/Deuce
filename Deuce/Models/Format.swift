//
//  Format.swift
//  Deuce
//
//  Created by Austin Conlon on 2/10/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation

struct Format: Codable, Identifiable {
    var id: Int
    var name: String
    var minimumSetsToWinMatch: Int
    var thirdSetSupertiebreak: Bool
    var noAd: Bool
    var isDoubles: Bool
}

/// Backwards compatibility.
enum RulesFormats: String, Codable {
    case main = "Main"
    case alternate = "Alternate"
    case noAd = "No-Ad"
    case doubles = "Doubles"
}

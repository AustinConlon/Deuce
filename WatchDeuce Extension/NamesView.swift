//
//  NamesView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 3/4/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct NamesView: View {
    @Binding var match: Match
    
    var body: some View {
        Form {
            TextField(match.playerTwoName, text: $match.playerTwoName)
            TextField(match.playerFourName, text: $match.playerFourName)
            TextField(match.playerThreeName, text: $match.playerThreeName)
            TextField(match.playerOneName, text: $match.playerOneName)
        }
        .textContentType(.name)
        .navigationBarTitle("Done")
    }
}


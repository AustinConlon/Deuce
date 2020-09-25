//
//  InitialView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/10/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct InitialView: View {
    @State var matchInProgress = false
    
    var body: some View {
        FormatList(matchInProgress: $matchInProgress) { MatchView(match: Match(format: $0), matchInProgress: $matchInProgress) }
        .environmentObject(UserData())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FormatList(matchInProgress: .constant(false)) { MatchView(match: Match(format: $0), matchInProgress: .constant(false)) }
        .environmentObject(UserData())
    }
}

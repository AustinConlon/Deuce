//
//  ContentView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/10/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        FormatList { MatchView(match: Match(format: $0)) }
            .environmentObject(UserData())
            .onAppear() {
                let workout = Workout()
                workout.requestAuthorization()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FormatList { MatchView(match: Match(format: $0)) }
        .environmentObject(UserData())
    }
}

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
    @State var isDoubles = false
    
    var body: some View {
        FormatList() { MatchView(match: Match(format: $0, isDoubles: $isDoubles)) }
            .environmentObject(UserData())
            .toolbar {
                Toggle(isOn: $isDoubles) {
                    Text("Doubles")
                }
                .padding()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FormatList() { MatchView(match: Match(format: $0)) }
        .environmentObject(UserData())
    }
}

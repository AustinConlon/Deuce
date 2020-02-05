//
//  MatchView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/4/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct MatchView: View {
    @State var match = Match()
    
    var body: some View {
        VStack {
            Button(action: {
                self.match.scorePoint(for: .playerTwo)
            }) {
                VStack {
                    Text(match.set.game.getScore(for: .playerTwo))
                    HStack {
                        ForEach(match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerTwo))
                        }
                    }
                }
            }
            
            Button(action: {
                self.match.scorePoint(for: .playerOne)
            }) {
                VStack {
                    HStack {
                        ForEach(match.sets, id: \.self) { set in
                            Text(String(set.score[0]))
                        }
                    }
                    Text(match.set.game.getScore(for: .playerOne))
                }
            }
        }
        .font(.largeTitle)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MatchView()
    }
}

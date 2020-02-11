//
//  MatchView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/4/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct MatchView: View {
    @EnvironmentObject var userData: UserData
    @State var match = Match()
    var format: Format
    
    var body: some View {
        VStack {
            Button(action: {
                self.match.scorePoint(for: .playerTwo)
            }) {
                VStack {
                    Text(match.currentGame.score(for: .playerTwo))
                    
                    HStack {
                        ForEach(match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerTwo))
                                .font(.headline)
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
                            Text(set.getScore(for: .playerOne))
                                .font(.headline)
                        }
                    }
                    
                    Text(match.currentGame.score(for: .playerOne))
                }
            }
        }
        .font(.largeTitle)
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        return MatchView(format: userData.formats[0]).environmentObject(userData)
    }
}

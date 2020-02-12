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
        GeometryReader { geometry in
            VStack() {
                PlayerTwo(match: self.$match)
                .frame(maxHeight: geometry.size.height / 2)
                PlayerOne(match: self.$match)
                .frame(maxHeight: geometry.size.height / 2)
            }
        }
        .font(.largeTitle)
        .navigationBarBackButtonHidden(true)
        .disabled(match.state == .finished ? true : false)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        return MatchView(format: userData.formats[0]).environmentObject(userData)
    }
}

struct PlayerTwo: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                self.match.scorePoint(for: .playerTwo)
            }) {
                VStack {
                    Text(self.match.currentGame.score(for: .playerTwo))
                    
                    Spacer()
                    
                    HStack {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerTwo))
                                .font(.headline)
                        }
                    }
                }
                .frame(height: geometry.size.height)
            }
        }
    }
}

struct PlayerOne: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                self.match.scorePoint(for: .playerOne)
            }) {
                VStack {
                    HStack {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerOne))
                                .font(.headline)
                        }
                    }
                    
                    Spacer()
                    
                    Text(self.match.currentGame.score(for: .playerOne))
                }
                .frame(height: geometry.size.height)
            }
        }
    }
}

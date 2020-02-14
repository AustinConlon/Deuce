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
                VStack(spacing: 0) {
                    ZStack() {
                        Image(systemName: "circle.fill")
                    }
                    .font(.caption)
                    .foregroundColor(self.match.servicePlayer == .playerTwo ? .green : .clear)
                    .frame(width: geometry.size.width / 3, alignment: self.serviceAlignment())
                    
                    Text(self.match.currentGame.score(for: .playerTwo))
                    
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
    
    func serviceAlignment() -> Alignment {
        switch match.currentGame.serviceSide {
        case .deuceCourt:
            return .leading
        case .adCourt:
            return .trailing
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
                VStack(spacing: 0) {
                    HStack {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerOne))
                                .font(.headline)
                        }
                    }
                    
                    Text(self.match.currentGame.score(for: .playerOne))
                    
                    ZStack() {
                        Image(systemName: "circle.fill")
                    }
                    .font(.caption)
                    .foregroundColor(self.match.servicePlayer == .playerOne ? .green : .clear)
                    .frame(width: geometry.size.width / 3, alignment: self.serviceAlignment())
                }
                .frame(height: geometry.size.height)
            }
        }
    }
    
    func serviceAlignment() -> Alignment {
        switch match.currentGame.serviceSide {
        case .deuceCourt:
            return .trailing
        case .adCourt:
            return .leading
        }
    }
}

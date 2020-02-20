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
    @State var match: Match
    @State var undoStack = Stack<Match>()
    var workout = Workout()
    
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
        .navigationBarTitle(match.format.rawValue)
        .disabled(match.state == .finished ? true : false)
        .edgesIgnoringSafeArea(.bottom)
        .contextMenu {
            Button(action: {
                self.match.undo()
            }) {
                VStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Undo")
                }
            }
            
            Button(action: {
                self.workout.start()
            }) {
                VStack {
                    Image(systemName: "chevron.right.2")
                    Text("Start Workout")
                }
            }

            Button(action: {
                self.workout.stop()
            }) {
                VStack {
                    Image(systemName: "xmark")
                    Text("Stop Workout")
                }
            }
        }
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        let format = userData.formats[0]
        return MatchView(match: Match(format: format)).environmentObject(userData)
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
                    .frame(width: geometry.size.width / 3, alignment: self.playerTwoServiceAlignment())
                    
                    Text(self.playerTwoGameScore())
                    
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
    
    func playerTwoServiceAlignment() -> Alignment {
        if match.format == .noAd && match.currentSet.currentGame.pointsWon == [3, 3] && !match.currentSet.currentGame.isTiebreak {
            return .center
        } else {
            switch match.currentSet.currentGame.serviceSide {
            case .deuceCourt:
                return .leading
            case .adCourt:
                return .trailing
            }
        }
    }
    
    func playerTwoGameScore() -> String {
        switch (match.currentSet.currentGame.advantage(), match.servicePlayer!) {
        case (.playerTwo, .playerOne):
            return "Ad out"
        case (.playerTwo, .playerTwo):
            return "Ad in"
        case (.playerOne, _):
            return " "
        default:
            switch match.currentSet.currentGame.isTiebreak {
            case true:
                return String(match.currentSet.currentGame.pointsWon[1])
            case false:
                return match.currentSet.currentGame.score(for: .playerTwo)
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
                VStack(spacing: 0) {
                    HStack {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerOne))
                                .font(.headline)
                        }
                    }
                    
                    Text(self.playerOneGameScore())
                    
                    ZStack() {
                        Image(systemName: "circle.fill")
                    }
                    .font(.caption)
                    .foregroundColor(self.match.servicePlayer == .playerOne ? .green : .clear)
                    .frame(width: geometry.size.width / 3, alignment: self.playerOneServiceAlignment())
                }
                .frame(height: geometry.size.height)
            }
        }
    }
    
    func playerOneServiceAlignment() -> Alignment {
        if match.format == .noAd && match.currentSet.currentGame.pointsWon == [3, 3] && !match.currentSet.currentGame.isTiebreak {
            return .center
        } else {
            switch match.currentSet.currentGame.serviceSide {
            case .deuceCourt:
                return .trailing
            case .adCourt:
                return .leading
            }
        }
    }
    
    func playerOneGameScore() -> String {
        switch (match.currentSet.currentGame.advantage(), match.servicePlayer!) {
        case (.playerOne, .playerOne):
            return "Ad in"
        case (.playerOne, .playerTwo):
            return "Ad out"
        case (.playerTwo, _):
            return " "
        default:
            switch match.currentSet.currentGame.isTiebreak {
            case true:
                return String(match.currentSet.currentGame.pointsWon[0])
            case false:
                return match.currentSet.currentGame.score(for: .playerOne)
            }
        }
    }
}

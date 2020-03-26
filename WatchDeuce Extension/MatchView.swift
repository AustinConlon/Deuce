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
    var undoStack = Stack<Match>()
    
    @State var singlesServiceAlert = true
    @State var showingNamesSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                PlayerTwo(match: self.$match)
                .frame(maxHeight: geometry.size.height / 2)
                
                Divider()
                
                PlayerOne(match: self.$match)
                .frame(maxHeight: geometry.size.height / 2)
            }
            
            HStack {
                Image(systemName: "arrow.down").padding()
                Spacer()
                Image(systemName: "arrow.up").padding()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .foregroundColor(self.match.isChangeover() ? .secondary : .clear)
            .zIndex(0.0)
        }
        .font(.largeTitle)
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(match.state == .playing ? LocalizedStringKey(title()) : "")
        .disabled(match.state == .finished ? true : false)
        .edgesIgnoringSafeArea(.bottom)
        .contextMenu {
            Button(action: {
                self.showingNamesSheet.toggle()
            }) {
                VStack {
                    Image(systemName: "pencil")
                    Text("Player Names")
                }
            }
            .sheet(isPresented: $showingNamesSheet) {
                NamesView(match: self.$match)
            }
            
            Button(action: {
                self.match.undoStack.items.count >= 1 ? self.match.undo() : self.singlesServiceAlert.toggle()
            }) {
                VStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Undo")
                }
            }
            
            NavigationLink(destination: FormatList { MatchView(match: Match(format: $0)) }) {
                VStack {
                    Image(systemName: "archivebox.fill")
                    Text("End Match")
                }
            }
        }
        .alert(isPresented: $singlesServiceAlert) {
            Alert(title: Text(LocalizedStringKey(serviceQuestion())),
                  primaryButton: .default(Text(LocalizedStringKey("You"))) {
                    self.match.servicePlayer = .playerOne
                    self.userData.workout.start()
                },
                  secondaryButton: .default(Text("Opponent")) {
                    self.match.servicePlayer = .playerTwo
                    self.userData.workout.start()
                })
        }
    }
    
    func serviceQuestion() -> String {
        switch match.format {
        case .doubles:
            return "Which team will serve first?"
        default:
            return "Who will serve first?"
        }
    }
    
    func title() -> String {
        if match.currentSet.isSetPoint() { return "Set Point" }
        if match.isBreakPoint() { return "Break Point" }
        return ""
    }
}

// MARK: - Opponent
struct PlayerTwo: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                self.match.scorePoint(for: .playerTwo)
                WKInterfaceDevice.current().play(self.match.isChangeover() ? .stop : .start)
            }) {
                VStack(spacing: 0) {
                    ZStack() {
                        self.playerTwoServiceImage()
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .foregroundColor(self.match.servicePlayer == .playerTwo ? .secondary : .clear)
                    .frame(width: geometry.size.width / 2, alignment: self.playerTwoServiceAlignment())
                    .animation(self.match.currentSet.currentGame.pointsPlayed > 0 ? .default : nil)
                    
                    Text(LocalizedStringKey(self.match.state == .finished ? self.playerTwoMedal() : self.playerTwoGameScore()))
                    .fontWeight(.medium)
                    
                    HStack {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerTwo))
                        }
                    }
                    .foregroundColor(.primary)
                    .font(.title)
                    .minimumScaleFactor(0.7)
                }
                .frame(height: geometry.size.height)
            }
            .accentColor(.blue)
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
        switch (match.currentSet.currentGame.advantage(), match.servicePlayer) {
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
    
    func playerTwoServiceImage() -> Image {
        if match.playerTwoName != "Opponent" {
            return Image(systemName: "\(match.playerTwoName.first!.lowercased()).circle.fill")
        } else {
            return Image(systemName: "circle.fill")
        }
    }
    
    func playerTwoMedal() -> String {
        switch match.winner! {
        case .playerOne:
            return "🥈"
        case .playerTwo:
            return "🥇"
        }
    }
}

// MARK: - User
struct PlayerOne: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                self.match.scorePoint(for: .playerOne)
                WKInterfaceDevice.current().play(self.match.isChangeover() ? .stop : .start)
            }) {
                VStack(spacing: 0) {
                    HStack() {
                        ForEach(self.match.sets, id: \.self) { set in
                            Text(set.getScore(for: .playerOne))
                        }
                    }
                    .accentColor(.primary)
                    .font(.title)
                    .minimumScaleFactor(0.7)
                    .animation(.default)
                    
                    Text(LocalizedStringKey(self.match.state == .finished ? self.playerOneMedal() : self.playerOneGameScore()))
                        .fontWeight(.medium)
                    
                    HStack(alignment: .bottom) {
                        self.playerOneServiceImage()
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .foregroundColor(self.match.servicePlayer == .playerOne ? .green : .clear)
                    .frame(width: geometry.size.width / 2, alignment: self.playerOneServiceAlignment())
                    .animation(self.match.currentSet.currentGame.pointsPlayed > 0 ? .default : nil)
                }
                .frame(height: geometry.size.height)
            }
            .accentColor(.blue)
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
        switch (match.currentSet.currentGame.advantage(), match.servicePlayer) {
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
    
    func playerOneServiceImage() -> Image {
        if match.playerOneName != "You" {
            return Image(systemName: "\(match.playerOneName.first!.lowercased()).circle.fill")
        } else {
            return Image(systemName: "circle.fill")
        }
    }
    
    func playerOneMedal() -> String {
        switch match.winner! {
        case .playerOne:
            return "🥇"
        case .playerTwo:
            return "🥈"
        }
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        let format = userData.formats[0]
        return Group {
            MatchView(match: Match(format: format))
                .environmentObject(userData)
                .environment(\.locale, .init(identifier: "en"))
//            MatchView(match: Match(format: format))
//                .environmentObject(userData)
//                .environment(\.locale, .init(identifier: "fr"))
        }
    }
}

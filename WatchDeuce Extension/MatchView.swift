//
//  MatchView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/4/20.
//  Copyright © 2021 Austin Conlon. All rights reserved.
//

import SwiftUI

struct MatchView: View {
    @EnvironmentObject var userData: UserData
    
    @State var match: Match
    @State var singlesServiceAlert = false
    @State var doublesServiceAlert = false
    @State var showingNamesSheet = false
    @State var showingMatchMenu = false
    
    @State var cloudController = CloudController()
    
    @State var showingInitialView = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                TeamTwo(match: $match)
                .frame(maxHeight: geometry.size.height / 2)
                
                Divider()
                
                TeamOne(match: $match)
                .frame(maxHeight: geometry.size.height / 2)
            }
            
            HStack {
                NavigationLink(destination: FormatList() { MatchView(match: Match(format: $0)) }
                .environmentObject(userData)
                .onAppear() {
                    match.stop()
                    cloudController.uploadToCloud(match: $match.wrappedValue)
                }, isActive: $showingInitialView) {
                    EmptyView()
                }
                
                Button(action: {
                    showingMatchMenu.toggle()
                }) {
                    Image(systemName: "ellipsis.circle.fill")
                        .foregroundColor(Color(.darkGray))
                        .font(.title)
                }
                
                Group {
                    Spacer()
                    Image(systemName: "arrow.up.arrow.down")
                }
                .foregroundColor(match.isChangeover() && match.state == .playing ? .secondary : .clear)
            }
            .frame(height: geometry.size.height)
            .buttonStyle(PlainButtonStyle())
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .font(.system(.largeTitle, design: .rounded))
        .navigationBarBackButtonHidden(true)
        .navigationBarTitle(match.state == .playing ? LocalizedStringKey(title()) : "")
        .edgesIgnoringSafeArea(.bottom)
        .alert(isPresented: .constant(match.servicePlayer == nil && match.isSingles)) {
            Alert(title: Text(LocalizedStringKey(serviceQuestion())),
                  primaryButton: .default(Text(LocalizedStringKey("You"))) {
                    match.servicePlayer = .playerOne
                    userData.workout.startWorkout()
                },
                  secondaryButton: .default(Text("Opponent")) {
                    match.servicePlayer = .playerTwo
                    userData.workout.startWorkout()
                })
        }
        .actionSheet(isPresented: .constant(match.isDoubles && match.currentSet.currentGame.pointsPlayed == 0 && match.currentSet.currentGame.currentPoint.serviceTeam == nil)) {
            match.currentSet.gamesPlayed == 0 ? firstGameDoublesServiceSelection() : secondGameDoublesServiceSelection()
        }
        .sheet(isPresented: $showingMatchMenu) {
            MatchMenu(match: $match, singlesServiceAlert: $singlesServiceAlert, showingMatchMenu: $showingMatchMenu, showingInitialView: $showingInitialView)
        }
        .onAppear {
            if match.servicePlayer == nil {
                match.isDoubles ? doublesServiceAlert.toggle() : singlesServiceAlert.toggle()
            }
        }
    }
    
    func firstGameDoublesServiceSelection() -> ActionSheet {
        ActionSheet(title: Text(serviceQuestion()),
                    buttons: [
                        .default(Text(LocalizedStringKey("Opponent"))) {
                            match.servicePlayer = .playerTwo
                            userData.workout.startWorkout()
                        },
                        .default(Text(LocalizedStringKey("Opponent's Partner"))) {
                            match.servicePlayer = .playerFour
                            userData.workout.startWorkout()
                        },
                        .default(Text(LocalizedStringKey("Your Partner"))) {
                            match.servicePlayer = .playerThree
                            userData.workout.startWorkout()
                        },
                        .default(Text(LocalizedStringKey("You"))) {
                            match.servicePlayer = .playerOne
                            userData.workout.startWorkout()
                        }
                    ]
                    .reversed())
    }
    
    func secondGameDoublesServiceSelection() -> ActionSheet {
        ActionSheet(title: Text(serviceQuestion()),
                    buttons: secondGameActionSheetButtons()
                    .reversed())
    }
    
    func secondGameActionSheetButtons() -> [ActionSheet.Button] {
        switch match.currentSet.currentGame.currentPoint.servicePlayer! {
        case .playerOne, .playerThree:
            return [
                .default(Text(LocalizedStringKey("Your Partner"))) {
                    match.servicePlayer = .playerThree
                    userData.workout.startWorkout()
                },
                .default(Text(LocalizedStringKey("You"))) {
                    match.servicePlayer = .playerOne
                    userData.workout.startWorkout()
                }
            ]
        case .playerTwo, .playerFour:
            return [
                .default(Text(LocalizedStringKey("Opponent"))) {
                    match.servicePlayer = .playerTwo
                    userData.workout.startWorkout()
                },
                .default(Text(LocalizedStringKey("Opponent's Partner"))) {
                    match.servicePlayer = .playerFour
                    userData.workout.startWorkout()
                }
            ]
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
        if match.currentSet.currentGame.pointsWon == [0, 0] {
            if match.isSupertiebreak { return "Supertiebreak" }
            if match.currentSet.currentGame.isTiebreak { return "Tiebreak" }
        }
        if match.isMatchPoint() { return "Match Point" }
        if match.currentSet.isSetPoint() { return "Set Point" }
        if match.currentSet.currentGame.currentPoint.isBreakpoint { return "Break Point" }
        return ""
    }
}

// MARK: - Opponent
struct TeamTwo: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                match.scorePoint(for: .teamTwo)
                WKInterfaceDevice.current().play(match.isChangeover() ? .stop : .start)
            }) {
                VStack(spacing: 0) {
                    ZStack() {
                        teamTwoServiceImage()
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .foregroundColor(teamTwoServiceColor())
                    .frame(width: geometry.size.width / 2, alignment: playerTwoServiceAlignment())
                    .animation(match.currentSet.currentGame.pointsPlayed > 0 && !match.currentSet.currentGame.isTiebreak ? .default : nil)
                    
                    Text(LocalizedStringKey(teamTwoGameScore()))
                        .fontWeight(.semibold)
                        .overlay(match.winner == .teamTwo ? Image(systemName: "crown.fill").foregroundColor(.yellow) : nil)
                    
                    HStack {
                        ForEach(match.sets, id: \.self) { set in
                            Text(set.score(of: .teamTwo))
                        }
                    }
                    .font(Font.title.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .animation(match.allPointsPlayed.count > 0 ? .default : .none)
                    .foregroundColor(.primary)
                }
                .frame(height: geometry.size.height)
            }
            .disabled(match.state == .finished ? true : false)
            .buttonStyle(BorderedButtonStyle(tint: .blue))
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
    
    func teamTwoGameScore() -> String {
        if match.winner != nil { return " " }
        
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
                return match.currentSet.currentGame.score(of: .teamTwo)
            }
        }
    }
    
    func teamTwoServiceImage() -> Image {
        Image(systemName: "circle.fill")
    }
    
    func teamTwoServiceColor() -> Color {
        switch (match.state, match.currentSet.currentGame.points.first?.servicePlayer, match.servicePlayer) {
        case (.playing, .playerTwo, .playerTwo):
            return .green
        case (.playing, .playerFour, .playerFour):
            return .secondary
        default:
            return .clear
        }
    }
}

// MARK: - User
struct TeamOne: View {
    @Binding var match: Match
    
    var body: some View {
        GeometryReader { geometry in
            Button(action: {
                match.scorePoint(for: .teamOne)
                WKInterfaceDevice.current().play(match.isChangeover() ? .stop : .start)
            }) {
                VStack(spacing: 0) {
                    HStack {
                        ForEach(match.sets, id: \.self) { set in
                            Text(set.score(of: .teamOne))
                        }
                    }
                    .font(Font.title.monospacedDigit())
                    .minimumScaleFactor(0.7)
                    .animation(match.allPointsPlayed.count > 0 ? .default : .none)
                    .foregroundColor(.primary)
                    
                    Text(LocalizedStringKey(teamOneGameScore()))
                        .fontWeight(.semibold)
                        .overlay(match.winner == .teamOne ? Image(systemName: "crown.fill").foregroundColor(.yellow) : nil)
                    
                    ZStack {
                        teamOneServiceImage()
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .foregroundColor(teamOneServiceColor())
                    .frame(width: geometry.size.width / 2, alignment: teamOneServiceAlignment())
                    .animation(match.currentSet.currentGame.pointsPlayed > 0 && !match.currentSet.currentGame.isTiebreak ? .default : nil)
                }
                .frame(height: geometry.size.height)
            }
            .disabled(match.state == .finished ? true : false)
            .buttonStyle(BorderedButtonStyle(tint: .blue))
        }
    }
    
    func teamOneServiceAlignment() -> Alignment {
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
    
    func teamOneGameScore() -> String {
        if match.winner != nil { return " " }
        
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
                return match.currentSet.currentGame.score(of: .teamOne)
            }
        }
    }
    
    func teamOneServiceImage() -> Image {
        Image(systemName: "circle.fill")
    }
    
    func teamOneServiceColor() -> Color {
        switch (match.state, match.currentSet.currentGame.points.first?.servicePlayer, match.servicePlayer) {
        case (.playing, .playerOne, .playerOne):
            return .green
        case (.playing, .playerThree, .playerThree):
            return .secondary
        default:
            return .clear
        }
    }
}

struct MatchView_Previews: PreviewProvider {
    static var previews: some View {
        let userData = UserData()
        let format = userData.formats[3]
        return Group {
            MatchView(match: Match(format: format))
                .environmentObject(userData)
                .environment(\.locale, .init(identifier: "en"))
            
            MatchView(match: Match(format: format))
                .environmentObject(userData)
                .environment(\.locale, .init(identifier: "fr"))
        }
    }
}

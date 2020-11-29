//
//  MatchDetail.swift
//  Deuce
//
//  Created by Austin Conlon on 5/8/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct MatchDetail: View {
    @State private var match: Match
    private var completion: (Match) -> Void
    
    init(match: Match, completion: @escaping (Match) -> Void) {
        self._match = State(initialValue: match)
        self.completion = completion
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Image(systemName: "calendar.circle.fill")
                Text(date())
            }
            .padding(.top)
            
            GroupBox {
                Score(match: $match)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                Text(match.notes)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    
                    .foregroundColor(.clear)
                    .overlay(TextEditor(text: $match.notes))
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)
            
            
            Divider()
            
            HStack {
                Label {
                    Text(LocalizedStringKey(match.playerOneName ?? "You"))
                        .fontWeight(match.winner == .playerOne ? .bold : .regular)
                } icon: {
                    Image(systemName: "applewatch")
                        .foregroundColor(match.winner == .playerOne ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
                
                Text(LocalizedStringKey(match.playerTwoName ?? "Opponent"))
                    .fontWeight(match.winner == .playerTwo ? .bold : .regular)
                    .frame(maxWidth: .infinity)
            }
            
            Statistics(match: match)
        }
        .onDisappear() {
            completion(match)
        }
    }
    
    func date() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        return dateFormatter.string(from: match.date)
    }
}

struct MatchDetail_Previews: PreviewProvider {
    static var previews: some View {
        let randomlyGeneratedMatch = Match.random()
        let matchDetail = MatchDetail(match: randomlyGeneratedMatch) { newMatch in }
        
        return matchDetail
            .preferredColorScheme(.light)
            .environment(\.locale, .init(identifier: "en"))
    }
}

struct Score: View {
    @Binding var match: Match
    
    var body: some View {
        VStack(alignment: .trailing) {
            HStack(alignment: .bottom) {
                Image(systemName: "applewatch")
                    .scaleEffect(0.7)
                    .foregroundColor(match.winner == .playerOne ? .primary : .secondary)
                    .padding(.trailing)
                
                ForEach(match.sets, id: \.self) { set in
                    VStack {
                        Text(String(set.gamesWon[1]))
                            .fontWeight(set.winner == .playerTwo ? .semibold : .regular)
                        Text(String(set.gamesWon[0]))
                            .fontWeight(set.winner == .playerOne ? .semibold : .regular)
                    }
                }
            }
        }
        .font(Font.largeTitle.monospacedDigit())
    }
}

struct Statistics: View {
    let match: Match
    
    var body: some View {
        HStack() {
            VStack {
                Text(String(match.teamOnePointsWon))
                Text(String(match.totalGamesWon(by: .playerOne)))
                Text("\(playerOneBreakPointsWon)/\(playerOneBreakPointsPlayed)")
                Text("\(playerOneServicePointsWon)/\(playerOneServicePointsPlayed)")
                Text("\(playerOneReturnPointsWon)/\(playerTwoServicePointsPlayed)")
            }
            .padding(.leading, 10)
            
            Spacer()
            
            VStack {
                Text("Points Won")
                Text("Games Won")
                Text("Break Points Won/Played")
                Text("Service Points Won/Played")
                Text("Return Points Won/Played")
            }
            .foregroundColor(.secondary)
            
            Spacer()
            
            VStack {
                Text(String(match.teamTwoPointsWon))
                Text(String(match.totalGamesWon(by: .playerTwo)))
                Text("\(playerTwoBreakPointsWon)/\(playerTwoBreakPointsPlayed)")
                Text("\(playerTwoServicePointsWon)/\(playerTwoServicePointsPlayed)")
                Text("\(playerTwoReturnPointsWon)/\(playerOneServicePointsPlayed)")
            }
            .padding(.trailing, 10)
        }
        .padding(.top)
    }
    
    var playerOneBreakPointsWon: String {
        if let playerOneBreakPointsWon = match.playerOneBreakPointsWon {
            return String(playerOneBreakPointsWon)
        } else {
            return "-"
        }
    }
    
    var playerTwoBreakPointsWon: String {
        if let playerTwoBreakPointsWon = match.playerTwoBreakPointsWon {
            return String(playerTwoBreakPointsWon)
        } else {
            return "-"
        }
    }
    
    var playerOneBreakPointsPlayed: String {
        if let playerOneBreakPointsPlayed = match.playerOneBreakPointsPlayed {
            return String(playerOneBreakPointsPlayed)
        } else {
            return "-"
        }
    }
    
    var playerTwoBreakPointsPlayed: String {
        if let playerTwoBreakPointsPlayed = match.playerTwoBreakPointsPlayed {
            return String(playerTwoBreakPointsPlayed)
        } else {
            return "-"
        }
    }
    
    var playerOneServicePointsWon: String {
        if let playerOneServicePointsWon = match.playerOneServicePointsWon {
            return String(playerOneServicePointsWon)
        } else {
            return "-"
        }
    }
    
    var playerTwoServicePointsWon: String {
        if let playerTwoServicePointsWon = match.playerTwoServicePointsWon {
            return String(playerTwoServicePointsWon)
        } else {
            return "-"
        }
    }
    
    var playerOneServicePointsPlayed: String {
        if let playerOneServicePointsPlayed = match.playerOneServicePointsPlayed {
            return String(playerOneServicePointsPlayed)
        } else {
            return "-"
        }
    }
    
    var playerTwoServicePointsPlayed: String {
        if let playerTwoServicePointsPlayed = match.playerTwoServicePointsPlayed {
            return String(playerTwoServicePointsPlayed)
        } else {
            return "-"
        }
    }
    
    var playerOneReturnPointsWon: String {
        if let playerTwoServicePointsWon = match.playerTwoServicePointsWon, let playerTwoServicePointsPlayed = match.playerTwoServicePointsPlayed {
            return String(playerTwoServicePointsPlayed - playerTwoServicePointsWon)
        } else {
            return "-"
        }
    }
    
    var playerTwoReturnPointsWon: String {
        if let playerOneServicePointsWon = match.playerOneServicePointsWon, let playerOneServicePointsPlayed = match.playerOneServicePointsPlayed {
            return String(playerOneServicePointsPlayed - playerOneServicePointsWon)
        } else {
            return "-"
        }
    }
}

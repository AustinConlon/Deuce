//
//  MatchDetail.swift
//  Deuce
//
//  Created by Austin Conlon on 5/8/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct MatchDetail: View {
    let match: Match
    
    var body: some View {
        NavigationView {
            ScrollView {
                HStack {
                    Image(systemName: "calendar")
                    Text(date())
                }
                
                Divider()
                
                HStack {
                    ForEach(match.sets, id: \.self) { set in
                        VStack {
                            Text(String(set.gamesWon[1]))
                            .fontWeight(set.winner == .playerTwo ? .semibold : .regular)
                            Text(String(set.gamesWon[0]))
                            .fontWeight(set.winner == .playerOne ? .semibold : .regular)
                        }
                        .font(Font.largeTitle.monospacedDigit())
                    }
                }
                
                Divider()
                
                HStack {
                    Text(match.playerOneName ?? "You")
                        .fontWeight(match.winner == .playerOne ? .bold : .regular)
                        .frame(maxWidth: .infinity)
                    Text(match.playerTwoName ?? "Opponent")
                        .fontWeight(match.winner == .playerTwo ? .bold : .regular)
                        .frame(maxWidth: .infinity)
                }
                
                HStack() {
                    VStack {
                        Text(String(match.totalPointsWon(by: .playerOne)))
                        Text(String(match.totalGamesWon(by: .playerOne)))
                        Text("\(match.playerOneServicePointsWon)/\(match.playerOneServicePointsPlayed)")
                        Text("\(match.playerOneReturnPointsWon)/\(match.playerTwoServicePointsPlayed)")
                        Text("\(match.playerOneBreakPointsPlayed)")
                    }
                    .padding(.leading)
                    
                    Spacer()
                    
                    VStack {
                        Text("Points Won")
                        Text("Games Won")
                        Text("Service Points Won/Played")
                        Text("Return Points Won/Played")
                        Text("Break Points Played")
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    VStack {
                        Text(String(match.totalPointsWon(by: .playerTwo)))
                        Text(String(match.totalGamesWon(by: .playerTwo)))
                        Text("\(match.playerTwoServicePointsWon)/\(match.playerTwoServicePointsPlayed)")
                        Text("\(match.playerTwoReturnPointsWon)/\(match.playerOneServicePointsPlayed)")
                        Text("\(match.playerTwoBreakPointsPlayed)")
                    }
                    .padding(.trailing)
                }
                .padding(.top)
            }
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
        return MatchDetail(match: randomlyGeneratedMatch)
            .preferredColorScheme(.dark)
    }
}

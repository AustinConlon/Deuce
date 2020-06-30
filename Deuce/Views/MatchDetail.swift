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
        VStack {
            HStack {
                Image(systemName: "calendar")
                Text(date())
            }
            
            Divider()
            
            HStack {
                ForEach(match.sets, id: \.self) { set in
                    VStack {
                        Text(String(set.gamesWon[1]))
                        Text(String(set.gamesWon[0]))
                    }
                    .font(Font.largeTitle.monospacedDigit())
                }
            }
                
            Divider()
            
            HStack {
                Text(match.playerOneName ?? "You").frame(maxWidth: .infinity)
                Text(match.playerTwoName ?? "Opponent").frame(maxWidth: .infinity)
            }
            
            HStack() {
                VStack {
                    Text(String(match.totalPointsWon(by: .playerOne)))
                    Text(String(match.totalGamesWon(by: .playerOne)))
                    Text(String(match.playerOneServicePointsPlayed))
                    Text(String(match.playerTwoServicePointsPlayed))
                    Text(String(match.playerOneBreakPointsPlayed))
                }
                .padding(.leading)
                
                Spacer()
                
                VStack {
                    Text("Points Won")
                    Text("Games Won")
                    Text("Service Points Played")
                    Text("Receiving Points Played")
                    Text("Break Points Played")
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                VStack {
                    Text(String(match.totalPointsWon(by: .playerTwo)))
                    Text(String(match.totalGamesWon(by: .playerTwo)))
                    Text(String(match.playerTwoServicePointsPlayed))
                    Text(String(match.playerOneServicePointsPlayed))
                    Text(String(match.playerTwoBreakPointsPlayed))
                }
                .padding(.trailing)
            }
            .padding()
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
        MatchDetail(match: Match.random())
    }
}

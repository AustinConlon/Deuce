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
                Text(match.playerOneName ?? "You")
                Text(match.playerTwoName ?? "Opponent")
            }
            
            HStack() {
                VStack {
                    Text(String(match.totalPointsWon(by: .playerOne)))
                    Text(String(match.totalGamesWon(by: .playerOne)))
                    Text(String(match.totalServicePointsPlayed(by: .playerOne)))
                    Text(String(match.totalReturningPointsPlayed(by: .playerOne)))
                    Text(String(match.totalBreakPointsPlayed(for: .playerOne)))
                }
                .padding(.leading)
                
                Spacer()
                
                VStack {
                    Text("Points Won")
                    Text("Games Won")
                    Text("Service Points Played")
                    Text("Returning Points Played")
                    Text("Break Points Played")
                }
                .foregroundColor(.secondary)
                
                Spacer()
                
                VStack {
                    Text(String(match.totalPointsWon(by: .playerTwo)))
                    Text(String(match.totalGamesWon(by: .playerTwo)))
                    Text(String(match.totalServicePointsPlayed(by: .playerTwo)))
                    Text(String(match.totalReturningPointsPlayed(by: .playerTwo)))
                    Text(String(match.totalBreakPointsPlayed(for: .playerTwo)))
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

extension HorizontalAlignment {
    private enum StatisticsAndTitle: AlignmentID {
        static func defaultValue(in context: ViewDimensions) -> CGFloat {
            return context[HorizontalAlignment.center]
        }
    }
    static let statisticsAndTitle = HorizontalAlignment(StatisticsAndTitle.self)
}

struct MatchDetail_Previews: PreviewProvider {
    static var previews: some View {
        MatchDetail(match: Match.random())
    }
}

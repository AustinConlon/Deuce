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
                VStack {
                    Text(String(match.totalPointsWon(by: .playerOne)))
                    Text(String(match.totalGamesWon(by: .playerOne)))
                }
                .font(.title)
                .padding(.horizontal)
                
                Spacer()
                
                VStack {
                    Text("Points Won")
                    Text("Games Won")
                    
                }
                .font(.body)
                
                Spacer()
                
                VStack {
                    Text(String(match.totalPointsWon(by: .playerTwo)))
                    Text(String(match.totalGamesWon(by: .playerTwo)))
                }
                .font(.title)
                .padding(.horizontal)
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

//
//  FormatList.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/8/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct FormatList<MatchView: View>: View {
    @EnvironmentObject private var userData: UserData
    
    @Binding var matchInProgress: Bool
    
    let matchViewProducer: (Format) -> MatchView
    
    var body: some View {
        List {
            ForEach(userData.formats) { format in
                NavigationLink(
                destination:
                self.matchViewProducer(format).environmentObject(self.userData),
                isActive: $matchInProgress) {
                    FormatRow(format: format)
                }
            }
        }
        .listStyle(CarouselListStyle())
        .navigationBarBackButtonHidden(true)
        .onAppear() {
            self.userData.workout.session?.state == .running ? self.userData.workout.endWorkout() : self.userData.workout.requestAuthorization()
        }
    }
}

struct FormatsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FormatList(matchInProgress: .constant(false)) { MatchView(match: Match(format: $0), matchInProgress: .constant(true)) }
                .environmentObject(UserData())
                .environment(\.locale, .init(identifier: "en"))
        }
    }
}

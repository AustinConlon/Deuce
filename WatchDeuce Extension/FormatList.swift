//
//  FormatList.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/8/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct FormatList<MatchView: View>: View {
    @EnvironmentObject var userData: UserData
    @EnvironmentObject var workoutManager: WorkoutManager
    
    let matchViewProducer: (Format) -> MatchView
    
    var body: some View {
        List {
            Button(action: /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Action@*/{}/*@END_MENU_TOKEN@*/) {
                /*@START_MENU_TOKEN@*//*@PLACEHOLDER=Content@*/Text("Button")/*@END_MENU_TOKEN@*/
            }
            
            ForEach(userData.formats) { format in
                NavigationLink(
                destination:
                self.matchViewProducer(format).environmentObject(self.userData)) {
                    FormatRow(format: format)
                }
            }
        }
        .listStyle(CarouselListStyle())
        .navigationBarBackButtonHidden(true)
        .onAppear() {
            self.workoutManager.session?.state == .running ? self.workoutManager.endWorkout() : self.workoutManager.requestAuthorization()
        }
    }
}

struct FormatsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FormatList() { MatchView(match: Match(format: $0)) }
                .environmentObject(UserData())
                .environment(\.locale, .init(identifier: "en"))
        }
    }
}

//
//  WorkoutView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 10/6/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct WorkoutTabView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @State var tabSelection: TabSelection = .workout
    @Binding var workoutInProgress: Bool
    
    enum TabSelection {
        case menu
        case workout
    }
    
    var body: some View {
        TabView(selection: $tabSelection) {
            WorkoutMenu(pauseAction: pauseAction, endAction: endAction)
                .tag(TabSelection.menu)
            
            WorkoutView()
                .tag(TabSelection.workout)
        }
        .tabViewStyle(PageTabViewStyle())
    }
    
    func pauseAction() {
        withAnimation { self.tabSelection = .workout }
        workoutManager.togglePause()
    }
    
    func endAction() {
        workoutManager.endWorkout()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.tabSelection = .workout
        }
        
        workoutInProgress = false
    }
}

struct WorkoutTabView_Previews: PreviewProvider {
    @State static var workoutInProgress = true
    static var previews: some View {
        Group {
            WorkoutTabView(tabSelection: .menu, workoutInProgress: $workoutInProgress)
            .previewDisplayName("Menu Tab")
                
            WorkoutTabView(tabSelection: .workout, workoutInProgress: $workoutInProgress)
            .previewDisplayName("Workout Tab")
        }
        .environmentObject(WorkoutManager())
    }
}

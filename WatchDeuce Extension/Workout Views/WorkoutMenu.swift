//
//  WorkoutMenu.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 10/6/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct WorkoutMenu: View {
    @EnvironmentObject var workoutSession: WorkoutManager
    
    @State var workoutPaused: Bool = false
    let pauseAction: () -> Void
    let endAction: () -> Void
    
    var body: some View {
        Text("Hello, World!")
    }
}

struct WorkoutMenu_Previews: PreviewProvider {
    static var pauseAction = { }
    static var endAction = { }
    
    static var previews: some View {
        WorkoutMenu(pauseAction: pauseAction, endAction: endAction)
    }
}

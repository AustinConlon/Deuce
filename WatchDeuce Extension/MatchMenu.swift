//
//  MatchMenu.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 9/18/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct MatchMenu: View {
    @EnvironmentObject var userData: UserData
    
    @Binding var match: Match
    @Binding var singlesServiceAlert: Bool
    @Binding var showingMatchMenu: Bool
    
    @Binding var cloudController: CloudController
    
    @Binding var matchInProgress: Bool
    
    @Binding var showingInitialView: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                showingMatchMenu.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.match.undoStack.items.count >= 1 ? self.match.undo() : self.singlesServiceAlert.toggle()
                }
            }) {
                Label("Undo", systemImage: "arrow.counterclockwise.circle.fill")
                    .foregroundColor(.blue)
            }
            .padding(.vertical)
            
            Button(action: {
                showingMatchMenu = false
                showingInitialView = true
            }) {
                Label("End", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .padding(.vertical)
        }
        .buttonStyle(PlainButtonStyle())
        .font(.title)
    }
}

struct MatchMenu_Previews: PreviewProvider {
    static var previews: some View {
        MatchMenu(match: .constant(Match.random()), singlesServiceAlert: .constant(false), showingMatchMenu: .constant(true), cloudController: .constant(CloudController()), matchInProgress: .constant(true), showingInitialView: .constant(false))
    }
}

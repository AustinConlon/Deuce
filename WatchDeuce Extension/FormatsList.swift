//
//  FormatsList.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/8/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct FormatsList: View {
    @EnvironmentObject private var userData: UserData
    
    let matchViewProducer: (Match) -> MatchView
    
    var body: some View {
        List {
            ForEach(userData.formats) { format in
                NavigationLink(
                destination:
                self.matchViewProducer(format).environmentObject(self.userData)) {
                    
                }
            }
        }
    }
}

struct FormatsView_Previews: PreviewProvider {
    static var previews: some View {
        FormatsList()
    }
}

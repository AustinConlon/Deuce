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
    @State private var isPresented = false
    
    let matchViewProducer: (Format) -> MatchView
    
    var body: some View {
        List {
            ForEach(userData.formats) { format in
                NavigationLink(
                destination:
                self.matchViewProducer(format).environmentObject(self.userData)) {
                    FormatRow(format: format)
                }
            }
        }
    }
    
//    matchViewProducer(format).environmentObject(self.userData)) {
//        FormatRow(format: format)
//    }
}

struct FormatsView_Previews: PreviewProvider {
    static var previews: some View {
        FormatList { MatchView(format: $0) }
        .environmentObject(UserData())
    }
}

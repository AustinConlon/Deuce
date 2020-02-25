//
//  StartingService.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 2/21/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct StartingService: View {
    @EnvironmentObject private var userData: UserData
    
    let matchViewProducer: (Format) -> MatchView
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct StartingService_Previews: PreviewProvider {
    static var previews: some View {
        StartingService()
    }
}

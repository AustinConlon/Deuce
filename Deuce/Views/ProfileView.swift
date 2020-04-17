//
//  ProfileView.swift
//  Deuce
//
//  Created by Austin Conlon on 4/15/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    @State var playerOneName: String = ""
    
    var body: some View {
        Form {
            TextField("Your Name", text: $playerOneName)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

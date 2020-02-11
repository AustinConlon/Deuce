//
//  UserData.swift
//  Deuce
//
//  Created by Austin Conlon on 2/8/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Combine

final class UserData: ObservableObject {
    @Published var formats = formatData
}

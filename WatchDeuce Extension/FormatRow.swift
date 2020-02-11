//
//  FormatRow.swift
//  Deuce
//
//  Created by Austin Conlon on 2/10/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct FormatRow: View {
    var format: Format
    
    var body: some View {
        Text(format.name)
    }
}

struct FormatsRow_Previews: PreviewProvider {
    static var previews: some View {
        FormatRow(format: formatData[0])
    }
}

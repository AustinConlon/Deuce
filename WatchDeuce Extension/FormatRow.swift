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
    var sets: String { "Best-of \(maximumSetsInMatch) sets" }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(LocalizedStringKey(format.name)).bold()
            Text(LocalizedStringKey(sets))
            Text(format.thirdSetSupertiebreak ? "3rd set is supertiebreak game" : "Tiebreak at 6-6 for all sets")
            Text(format.noAd ? "No-ad games" : "Advantage games")
        }
        .padding()
    }
    
    var maximumSetsInMatch: Int {
        /// More options will be added later.
        switch format.minimumSetsToWinMatch {
        default:
            return 3
        }
    }
}

struct FormatsRow_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FormatRow(format: formatData[0])
        }
    }
}

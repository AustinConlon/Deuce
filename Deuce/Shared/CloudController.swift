//
//  CloudController.swift
//  Deuce
//
//  Created by Austin Conlon on 3/29/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import CloudKit

struct CloudController {
    let database = CKContainer.default().privateCloudDatabase
    
    var matchRecord: CKRecord!
    
    func uploadToCloud(match: Match) {
        if let matchData = try? PropertyListEncoder().encode(match) {
            let matchRecord = CKRecord(recordType: "Match")
            matchRecord["matchData"] = matchData as NSData
            
            database.save(matchRecord) { (savedRecord, error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            }
        }
    }
}

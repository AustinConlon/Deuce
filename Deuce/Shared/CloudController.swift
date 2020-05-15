//
//  CloudController.swift
//  Deuce
//
//  Created by Austin Conlon on 3/29/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import CloudKit

struct CloudController {
    let database = CKContainer(identifier: "iCloud.com.example.Deuce.watchkitapp.watchkitextension").privateCloudDatabase
    
    var matchRecord: CKRecord!
    
    func uploadToCloud(match: Match) {
        if let matchData = try? PropertyListEncoder().encode(match) {
            print(matchData)
//            let matchRecord = CKRecord(recordType: "Match")
//            matchRecord["matchData"] = matchData as NSData
//
//            database.save(matchRecord) { (savedRecord, error) in
//                print(savedRecord.debugDescription)
//                if let error = error {
//                    print(error.localizedDescription)
//                }
//            }
        } else {
            print("Failed to encode")
        }
    }
}

//
//  CloudController.swift
//  Deuce
//
//  Created by Austin Conlon on 3/29/20.
//  Copyright © 2021 Austin Conlon. All rights reserved.
//

import CloudKit
import os.log

struct CloudController {
    let database = CKContainer(identifier: "iCloud.com.example.Deuce.watchkitapp.watchkitextension").privateCloudDatabase
    
    var matchRecord: CKRecord!
    
    func uploadToCloud(match: Match) {
        if let matchData = try? PropertyListEncoder().encode(match) {
            let matchRecord = CKRecord(recordType: "Match")
            matchRecord["matchData"] = matchData as NSData

            database.save(matchRecord) { (record, error) in
                if let error = error {
                    self.reportError(error)
                }
            }
        } else {
            print("Failed to encode")
        }
    }
    
    // MARK: - Helpers

    private func reportError(_ error: Error) {
        guard let error = error as? CKError else {
            os_log("Not a CKError: \(error.localizedDescription)")
            return
        }

        switch error.code {
        case .partialFailure:
            // Iterate through error(s) in partial failure and report each one.
            let errorDictionary = error.userInfo[CKPartialErrorsByItemIDKey] as? [NSObject: CKError]
            if let errorDictionary = errorDictionary {
                for (_, error) in errorDictionary {
                    reportError(error)
                }
            }
        case .unknownItem:
            os_log("CKError: Record not found.")
        case .notAuthenticated:
            os_log("CKError: An iCloud account must be signed in to write to the private database.")
        case .permissionFailure:
            os_log("CKError: An iCloud account permission failure occured.")
        case .networkUnavailable:
            os_log("CKError: The network is unavailable.")
        default:
            os_log("CKError: \(error.localizedDescription)")
        }
    }
}

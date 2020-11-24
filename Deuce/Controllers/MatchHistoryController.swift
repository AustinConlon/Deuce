//
//  MatchHistoryController.swift
//  Deuce
//
//  Created by Austin Conlon on 11/22/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation
import CloudKit
import UIKit

class MatchHistoryController {
    static let shared = MatchHistoryController()
    
    var matches = [Match]()
    
    let database = CKContainer(identifier: "iCloud.com.example.Deuce.watchkitapp.watchkitextension").privateCloudDatabase
    
    @Published var records = [CKRecord]() {
        didSet {
            if !records.isEmpty {
                matches.removeAll()
                
                for record in records {
                    let matchData = record["matchData"] as! Data
                    let propertyListDecoder = PropertyListDecoder()
                    do {
                        let match = try propertyListDecoder.decode(Match.self, from: matchData)
                        matches.append(match)
                    } catch {
                        print(error)
                    }
                }
                
                if records.count > oldValue.count && matches.count > 1, let previousMatchIndex = matches.index(0, offsetBy: 1, limitedBy: 1) {
                    if let previousPlayerOneName = matches[previousMatchIndex].playerOneName {
                        matches[0].playerOneName = previousPlayerOneName

                        let matchRecord = self.records[0]
                        if let matchData = try? PropertyListEncoder().encode(self.matches[0]) {
                            matchRecord["matchData"] = matchData as NSData

                            self.database.save(matchRecord) { (savedRecord, error) in
                                if let error = error { print(error.localizedDescription) }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchMatchRecords() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Match", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { (fetchedRecords, error) in
            if let fetchedRecords = fetchedRecords {
                self.records = fetchedRecords
            }
            
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
}

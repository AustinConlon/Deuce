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
    
    var records = [CKRecord]() {
        didSet {
            
        }
    }
    
    func fetchMatchRecords(completion: ([Match]) -> Void) {
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
        }
        
        completion(matches)
    }
}

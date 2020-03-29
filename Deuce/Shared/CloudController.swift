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
}

//
//  PracticeModeInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 5/17/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation


class PracticeModeInterfaceController: WKInterfaceController {

    @IBOutlet var activityRing: WKInterfaceActivityRing!
    
    override init() {
        
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

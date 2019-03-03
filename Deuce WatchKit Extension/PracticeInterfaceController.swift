//
//  PracticeInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 2/25/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation


class PracticeInterfaceController: WKInterfaceController {
    @IBOutlet weak var practiceTimer: WKInterfaceTimer!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        practiceTimer.start()
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

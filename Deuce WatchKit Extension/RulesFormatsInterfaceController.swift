//
//  RulesFormatsInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 5/2/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation


class RulesFormatsInterfaceController: WKInterfaceController {

    @IBOutlet weak var rulesFormatsTable: WKInterfaceTable!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        rulesFormatsTable.setRowTypes(["Main (Best-of 3 Sets)",
                                       "Alternate (Best-of 3 Sets)",
                                       "No-Ad (Best-of 3 Sets)"])
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        switch rowIndex {
        case 0:
            UserDefaults.standard.set("Main (Best-of 3 Sets)", forKey: "Type of Set")
        case 1:
            UserDefaults.standard.set("Alternate (Best-of 3 Sets)", forKey: "Type of Set")
        case 2:
            UserDefaults.standard.set("No-Ad (Best-of 3 Sets)", forKey: "Type of Set")
        default:
            break
        }
    }

}

enum RulesFormats {
    case main
    case alternate
    case noAd
}

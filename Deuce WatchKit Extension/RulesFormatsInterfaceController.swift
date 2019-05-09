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
    var rulesFormat = RulesFormats.main
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        rulesFormatsTable.setRowTypes([RulesFormats.main.rawValue,
                                       RulesFormats.alternate.rawValue,
                                       RulesFormats.noAd.rawValue])
    }
    
    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        switch rowIndex {
        case 0:
            rulesFormat = .main
        case 1:
            rulesFormat = .alternate
        case 2:
            rulesFormat = .noAd
        default:
            break
        }
        UserDefaults.standard.set(rulesFormat.rawValue, forKey: "Rules Format")
        dismiss()
    }

}

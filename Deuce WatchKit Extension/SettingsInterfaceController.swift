//
//  SettingsInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 4/1/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation


class SettingsInterfaceController: WKInterfaceController {

    @IBOutlet weak var picker: WKInterfacePicker!
    @IBOutlet weak var tiebreakSwitch: WKInterfaceSwitch!
    @IBOutlet weak var advantageSwitch: WKInterfaceSwitch!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        let oneSetPickerItem = WKPickerItem()
        oneSetPickerItem.title = "One set"
        oneSetPickerItem.caption = NSLocalizedString("Match Length", tableName: "Interface", comment: "Number of sets in the best-of match series.").uppercased()
        
        let bestOfThreeSetsPickerItem = WKPickerItem()
        bestOfThreeSetsPickerItem.title = NSLocalizedString("Best-of 3 sets", tableName: "Interface", comment: "First to win 2 sets")
        bestOfThreeSetsPickerItem.caption = NSLocalizedString("Match Length", tableName: "Interface", comment: "Number of sets in the best-of match series.").uppercased()
        
        let bestOfFiveSetsPickerItem = WKPickerItem()
        bestOfFiveSetsPickerItem.title = NSLocalizedString("Best-of 5 sets", tableName: "Interface", comment: "First to win 3 sets")
        bestOfFiveSetsPickerItem.caption = NSLocalizedString("Match Length", tableName: "Interface", comment: "Number of sets in the best-of match series.").uppercased()
        
        picker.setItems([oneSetPickerItem, bestOfThreeSetsPickerItem, bestOfFiveSetsPickerItem])
        picker.setSelectedItemIndex(1)
    }
    
    @IBAction func setMatchLength(_ value: Int) {
        switch value {
        case 0:
            UserDefaults.standard.set(1, forKey: "minimumSetsToWinMatch")
        case 1:
            UserDefaults.standard.set(2, forKey: "minimumSetsToWinMatch")
        case 2:
            UserDefaults.standard.set(3, forKey: "minimumSetsToWinMatch")
        default:
            break
        }
    }
    
    @IBAction func toggleTiebreak(_ value: Bool) {
        switch value {
        case true:
            advantageSwitch.setOn(false)
            UserDefaults.standard.set(0, forKey: "setType")
        case false:
            advantageSwitch.setOn(true)
            UserDefaults.standard.set(1, forKey: "setType")
        }
    }
    
    @IBAction func toggleAdvantage(_ value: Bool) {
        switch value {
        case true:
            tiebreakSwitch.setOn(false)
            UserDefaults.standard.set(1, forKey: "setType")
        case false:
            tiebreakSwitch.setOn(true)
            UserDefaults.standard.set(0, forKey: "setType")
        }
    }
}

//
//  SettingsInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 11/19/17.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import HealthKit

class SettingsInterfaceController: WKInterfaceController {
    // MARK: Properties
    var maximumSetCount = 1
    var setType: SetType = .tiebreak
    
    @IBOutlet var matchLengthLabel: WKInterfaceLabel!
    @IBOutlet var matchLengthSlider: WKInterfaceSlider!
    @IBOutlet weak var tiebreakSwitch: WKInterfaceSwitch!
    @IBOutlet weak var advantageSwitch: WKInterfaceSwitch!
    
    @IBAction func changeMatchLength(_ value: Float) {
        maximumSetCount = Int(value)
        switch maximumSetCount {
        case 3:
            matchLengthLabel.setText(NSLocalizedString("Best-of 3 sets", tableName: "Interface", comment: "First to win 2 sets wins the series"))
        case 5:
            matchLengthLabel.setText(NSLocalizedString("Best-of 5 sets", tableName: "Interface", comment: "First to win 3 sets wins the series"))
        default:
            matchLengthLabel.setText("1 set")
        }
    }
    
    @IBAction func toggleTiebreak(_ value: Bool) {
        switch value {
        case true:
            advantageSwitch.setOn(false)
            setType = .tiebreak
        case false:
            advantageSwitch.setOn(true)
            setType = .advantage
        }
    }
    
    @IBAction func toggleAdvantage(_ value: Bool) {
        switch value {
        case true:
            tiebreakSwitch.setOn(false)
            setType = .tiebreak
        case false:
            tiebreakSwitch.setOn(true)
            setType = .advantage
            dismiss()
        }
    }
}

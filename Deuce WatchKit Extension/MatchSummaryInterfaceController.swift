//
//  MatchSummaryInterfaceController.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 4/18/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import WatchKit
import Foundation


class MatchSummaryInterfaceController: WKInterfaceController {
    // MARK: Properties
    var match: Match?
    
    @IBOutlet weak var columnOneGroup: WKInterfaceGroup!
    @IBOutlet weak var columnOnePlayerOneSetLabel: WKInterfaceLabel!
    @IBOutlet weak var columnOnePlayerTwoSetLabel: WKInterfaceLabel!
    
    @IBOutlet weak var columnTwoGroup: WKInterfaceGroup!
    @IBOutlet weak var columnTwoPlayerOneSetLabel: WKInterfaceLabel!
    @IBOutlet weak var columnTwoPlayerTwoSetLabel: WKInterfaceLabel!
    
    @IBOutlet weak var columnThreeGroup: WKInterfaceGroup!
    @IBOutlet weak var columnThreePlayerOneSetLabel: WKInterfaceLabel!
    @IBOutlet weak var columnThreePlayerTwoSetLabel: WKInterfaceLabel!
    
    @IBOutlet weak var columnFourGroup: WKInterfaceGroup!
    @IBOutlet weak var columnFourPlayerOneSetLabel: WKInterfaceLabel!
    @IBOutlet weak var columnFourPlayerTwoSetLabel: WKInterfaceLabel!
    
    @IBOutlet weak var columnFiveGroup: WKInterfaceGroup!
    @IBOutlet weak var columnFivePlayerOneSetLabel: WKInterfaceLabel!
    @IBOutlet weak var columnFivePlayerTwoSetLabel: WKInterfaceLabel!
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        columnOneGroup.setHidden(true)
        columnTwoGroup.setHidden(true)
        columnThreeGroup.setHidden(true)
        columnFourGroup.setHidden(true)
        columnFiveGroup.setHidden(true)
        
        if let match = context as? Match {
            self.match = match
            unhideSetGroups()
            updateSetLabels()
        }
    }
    
    private func unhideSetGroups() {
        switch match?.sets.count {
        case 1:
            columnFiveGroup.setHidden(false)
        case 2:
            columnFiveGroup.setHidden(false)
            columnFourGroup.setHidden(false)
        case 3:
            columnFiveGroup.setHidden(false)
            columnFourGroup.setHidden(false)
            columnThreeGroup.setHidden(false)
        case 4:
            columnFiveGroup.setHidden(false)
            columnFourGroup.setHidden(false)
            columnThreeGroup.setHidden(false)
            columnTwoGroup.setHidden(false)
        case 5:
            columnFiveGroup.setHidden(false)
            columnFourGroup.setHidden(false)
            columnThreeGroup.setHidden(false)
            columnTwoGroup.setHidden(false)
            columnOneGroup.setHidden(false)
        default:
            break
        }
    }
    
    private func updateSetLabels() {
        switch match?.sets.count {
        case 1:
            columnFivePlayerOneSetLabel.setText(match?.set.getScore(for: .playerOne))
            columnFivePlayerTwoSetLabel.setText(match?.set.getScore(for: .playerTwo))
//            columnFivePlayerOneSetLabel.setText(match?.set.score[0])
//            columnFivePlayerTwoSetLabel.setText(match?.set.getScore(for: .playerTwo))
        case 2:
            columnOneGroup.setHidden(false)
            columnTwoGroup.setHidden(false)
        case 3:
            columnOneGroup.setHidden(false)
            columnTwoGroup.setHidden(false)
            columnThreeGroup.setHidden(false)
        case 4:
            columnOneGroup.setHidden(false)
            columnTwoGroup.setHidden(false)
            columnThreeGroup.setHidden(false)
            columnFourGroup.setHidden(false)
        case 5:
            columnOneGroup.setHidden(false)
            columnTwoGroup.setHidden(false)
            columnThreeGroup.setHidden(false)
            columnFourGroup.setHidden(false)
            columnFiveGroup.setHidden(false)
        default:
            break
        }
    }
}

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

class SettingsInterfaceController: WKInterfaceController, WCSessionDelegate {
    // MARK: Properties
    var session: WCSession!
    
    var maximumNumberOfSetsInMatch = 1 // Default match length is 1 set, other options are a best-of 3 and best-of 5 series.
        
    var typeOfSet: TypeOfSet = .tiebreak
    
    @IBOutlet var matchLengthLabel: WKInterfaceLabel!
    @IBOutlet var matchLengthSlider: WKInterfaceSlider!
    @IBOutlet var setTypeLabel: WKInterfaceLabel!
    @IBOutlet var startButton: WKInterfaceButton!

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func updateLabelForTypeOfSet() {
        switch (maximumNumberOfSetsInMatch, typeOfSet) {
        case (1, .advantage):
            setTypeLabel.setText(NSLocalizedString("Advantage set", tableName: "Interface", comment: "Must win by a margin of 2 sets"))
        case (1, .tiebreak):
            setTypeLabel.setText(NSLocalizedString("Tiebreak set", tableName: "Interface", comment: "When the set 6-6, it is then to be determined by a tiebreak game"))
        case (_, .advantage):
            setTypeLabel.setText(NSLocalizedString("Advantage sets", tableName: "Interface", comment: "Must win by a margin of 2 sets"))
        case (_, .tiebreak):
            setTypeLabel.setText(NSLocalizedString("Tiebreak sets", tableName: "Interface", comment: "When the set 6-6, it is then to be determined by a tiebreak game"))
        }
    }

    @IBAction func matchLengthSlider(_ value: Float) {
        maximumNumberOfSetsInMatch = Int(value)
        switch value {
        case 3:
            matchLengthLabel.setText(NSLocalizedString("Best-of 3 sets", tableName: "Interface", comment: "First to win 2 sets wins the series"))
        case 5:
            matchLengthLabel.setText(NSLocalizedString("Best-of 5 sets", tableName: "Interface", comment: "First to win 3 sets wins the series"))
        default:
            matchLengthLabel.setText("1 set")
        }
        updateLabelForTypeOfSet()
    }
    
    @IBAction func chooseTypeOfSetToBeAdvantage() {
        typeOfSet = .advantage
        updateLabelForTypeOfSet()
    }
    
    @IBAction func chooseTypeOfSetToBeTiebreak() {
        typeOfSet = .tiebreak
        updateLabelForTypeOfSet()
    }
    
    @IBAction func start() {
        let chooseOpponentToServeFirst = WKAlertAction(title: NSLocalizedString("Opponent", tableName: "Interface", comment: "Player the watch wearer is playing against"), style: .`default`) {
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, .two)
            self.pushController(withName: "scoreboard", context: match)
        }
        
        let chooseYourselfToServeFirst = WKAlertAction(title: NSLocalizedString("You", tableName: "Interface", comment: "Player wearing the watch"), style: .`default`) {
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, .one)
            self.pushController(withName: "scoreboard", context: match)
        }
        
        var coinTossWinnerMessage: String
        
        switch MatchManager.coinTossWinner {
        case .one:
            coinTossWinnerMessage = "You won the coin toss."
        case .two:
            coinTossWinnerMessage = "Your opponent won the coin toss."
        }
        
        let localizedCoinTossWinnerMessage = NSLocalizedString(coinTossWinnerMessage, tableName: "Interface", comment: "Announcement of which player won the coin toss")
        
        let localizedCoinTossQuestion = NSLocalizedString("Who will serve first?", tableName: "Interface", comment: "Question to the user of whether the coin toss winner chose to serve first or receive first")
        
        presentAlert(withTitle: localizedCoinTossWinnerMessage, message: localizedCoinTossQuestion, preferredStyle: .actionSheet, actions: [chooseOpponentToServeFirst, chooseYourselfToServeFirst])
    }
    
    @IBAction func startPracticeMode() {
        presentController(withName: "Practice Mode", context: nil)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let maximumNumberOfSetsInMatch = message["match length"] {
            self.maximumNumberOfSetsInMatch = maximumNumberOfSetsInMatch as! Int
            switch self.maximumNumberOfSetsInMatch {
            case 3:
                self.matchLengthSlider(3)
                self.matchLengthSlider.setValue(3)
            case 5:
                self.matchLengthSlider(5)
                self.matchLengthSlider.setValue(5)
            default:
                self.matchLengthSlider(1)
                self.matchLengthSlider.setValue(1)
            }
        } else if let typeOfSet = message["type of set"] {
            switch typeOfSet as! String {
            case "advantage":
                self.typeOfSet = .advantage
            default:
                self.typeOfSet = .tiebreak
            }
            self.updateLabelForTypeOfSet()
            self.startButton.setHidden(false)
        }
    }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let maximumNumberOfSetsInMatch = applicationContext["match length"] {
            self.maximumNumberOfSetsInMatch = maximumNumberOfSetsInMatch as! Int
            switch self.maximumNumberOfSetsInMatch {
            case 3:
                self.matchLengthSlider(3)
                self.matchLengthSlider.setValue(3)
            case 5:
                self.matchLengthSlider(5)
                self.matchLengthSlider.setValue(5)
            default:
                self.matchLengthSlider(1)
                self.matchLengthSlider.setValue(1)
            }
        } else if let typeOfSet = applicationContext["type of set"] {
            switch typeOfSet as! String {
            case "advantage":
                self.typeOfSet = .advantage
            default:
                self.typeOfSet = .tiebreak
            }
            self.updateLabelForTypeOfSet()
            self.startButton.setHidden(false)
        }
    }
}

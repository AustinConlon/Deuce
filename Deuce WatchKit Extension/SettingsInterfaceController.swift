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

class SettingsInterfaceController: WKInterfaceController, WCSessionDelegate, WKCrownDelegate {
    // MARK: Properties
    var session: WCSession!
    
    var maximumNumberOfSetsInMatch = 1 // Default match length is 1 set, other options are a best-of 3 and best-of 5 series.
    var typeOfSet: TypeOfSet?
    
    @IBOutlet var matchLengthLabel: WKInterfaceLabel!
    @IBOutlet var matchLengthSlider: WKInterfaceSlider!
    @IBOutlet var typeOfSetLabel: WKInterfaceLabel!
    @IBOutlet var startButton: WKInterfaceButton!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        crownSequencer.delegate = self
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self
            session.activate()
        }
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func updateLabelForTypeOfSet() {
        if typeOfSet == nil {
            switch maximumNumberOfSetsInMatch {
            case 1:
                typeOfSetLabel.setText("Type of set")
            default:
                typeOfSetLabel.setText("Type of sets")
            }
        }
        switch (maximumNumberOfSetsInMatch, typeOfSet) {
        case (1, .advantage?):
            typeOfSetLabel.setText("Advantage set")
        case (1, .tiebreak?):
            typeOfSetLabel.setText("Tiebreak set")
        case (_, .advantage?):
            typeOfSetLabel.setText("Advantage sets")
        case (_, .tiebreak?):
            typeOfSetLabel.setText("Tiebreak sets")
        case (_, .none):
            break
        }
    }

    @IBAction func matchLengthSlider(_ value: Float) {
        maximumNumberOfSetsInMatch = Int(value)
        switch value {
        case 3:
            matchLengthLabel.setText("Best-of three sets")
        case 5:
            matchLengthLabel.setText("Best-of five sets")
        default:
            matchLengthLabel.setText("One set")
        }
        updateLabelForTypeOfSet()
        session.sendMessage(["match length" : maximumNumberOfSetsInMatch], replyHandler: nil)
    }
    
    @IBAction func chooseTypeOfSetToBeAdvantage() {
        typeOfSet = .advantage
        updateLabelForTypeOfSet()
        startButton.setHidden(false)
        session.sendMessage(["set type" : "Advantage set"], replyHandler: nil)
    }
    
    @IBAction func chooseTypeOfSetToBeTiebreak() {
        typeOfSet = .tiebreak
        updateLabelForTypeOfSet()
        startButton.setHidden(false)
        session.sendMessage(["set type" : "Tiebreaker set"], replyHandler: nil)
    }
    
    @IBAction func start() {
        let chooseOpponentToServeFirst = WKAlertAction(title: "Opponent", style: .`default`) {
            self.session.sendMessage(["first server": "player two"], replyHandler: nil, errorHandler: nil)
            self.session.sendMessage(["start": "new match"], replyHandler: nil, errorHandler: nil)
            self.session.sendMessage(["live": self.maximumNumberOfSetsInMatch], replyHandler: nil)
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet!, playerThatWillServeFirst: .two)
            self.presentController(withName: "scoreboard", context: match)
            WKInterfaceDevice.current().play(.start)
        }
        let chooseYourselfToServeFirst = WKAlertAction(title: "You", style: .`default`) {
            self.session.sendMessage(["first server": "player one"], replyHandler: nil, errorHandler: nil)
            self.session.sendMessage(["start": "new match"], replyHandler: nil, errorHandler: nil)
            self.session.sendMessage(["live": self.maximumNumberOfSetsInMatch], replyHandler: nil)
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet!, playerThatWillServeFirst: .one)
            self.presentController(withName: "scoreboard", context: match)
            WKInterfaceDevice.current().play(.start)
        }
        var coinTossWinner: String
        switch MatchManager.coinTossWinner {
        case .one:
            coinTossWinner = "You"
        case .two:
            coinTossWinner = "Your opponent"
        }
        presentAlert(withTitle: "\(coinTossWinner) won the coin toss.", message: "Who will serve first?", preferredStyle: .actionSheet, actions: [chooseOpponentToServeFirst, chooseYourselfToServeFirst])
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) { }
}

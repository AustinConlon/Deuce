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
    @IBOutlet var typeOfSetLabel: WKInterfaceLabel!
    @IBOutlet var startButton: WKInterfaceButton!
    
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
        switch maximumNumberOfSetsInMatch {
        case 1:
            typeOfSetLabel.setText("Type of set")
        default:
            typeOfSetLabel.setText("Type of sets")
        }
        
        switch (maximumNumberOfSetsInMatch, typeOfSet) {
        case (1, .advantage):
            typeOfSetLabel.setText("Advantage set")
        case (1, .tiebreak):
            typeOfSetLabel.setText("Tiebreak set")
        case (_, .advantage):
            typeOfSetLabel.setText("Advantage sets")
        case (_, .tiebreak):
            typeOfSetLabel.setText("Tiebreak sets")
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
        session.sendMessage(["match length" : maximumNumberOfSetsInMatch], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
    }
    
    @IBAction func chooseTypeOfSetToBeAdvantage() {
        typeOfSet = .advantage
        updateLabelForTypeOfSet()
        startButton.setHidden(false)
        session.sendMessage(["type of set" : "advantage"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
    }
    
    @IBAction func chooseTypeOfSetToBeTiebreak() {
        typeOfSet = .tiebreak
        updateLabelForTypeOfSet()
        startButton.setHidden(false)
        session.sendMessage(["type of set" : "tiebreak"], replyHandler: nil, errorHandler: { Error in
            print(Error)
        })
    }
    
    @IBAction func start() {
        let chooseOpponentToServeFirst = WKAlertAction(title: "Opponent", style: .`default`) {
            self.session.sendMessage(["first server": "player two"], replyHandler: nil) { Error in
                print(Error)
            }
            self.session.sendMessage(["start": "new match"], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
            self.session.sendMessage(["live": self.maximumNumberOfSetsInMatch], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, .two)
            self.pushController(withName: "scoreboard", context: match)
            WKInterfaceDevice.current().play(.start)
        }
        let chooseYourselfToServeFirst = WKAlertAction(title: "You", style: .`default`) {
            self.session.sendMessage(["first server": "player one"], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
            self.session.sendMessage(["start": "new match"], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
            self.session.sendMessage(["live": self.maximumNumberOfSetsInMatch], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, .one)
            self.pushController(withName: "scoreboard", context: match)
            WKInterfaceDevice.current().play(.start)
        }
        var coinTossWinner: String
        switch MatchManager.coinTossWinner {
        case .one:
            coinTossWinner = "You"
            WKInterfaceDevice.current().play(.success)
        case .two:
            coinTossWinner = "Your opponent"
            WKInterfaceDevice.current().play(.failure)
        }
        presentAlert(withTitle: "\(coinTossWinner) won the coin toss.", message: "Who will serve first?", preferredStyle: .actionSheet, actions: [chooseOpponentToServeFirst, chooseYourselfToServeFirst])
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

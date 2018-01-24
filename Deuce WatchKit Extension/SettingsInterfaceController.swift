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
    
    @IBOutlet var matchLengthLabel: WKInterfaceLabel!
    @IBOutlet var matchLengthSlider: WKInterfaceSlider!
    @IBOutlet var setTypeSwitch: WKInterfaceSwitch!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
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

    @IBAction func matchLengthSlider(_ value: Float) {
        ScoreManager.matchLength = Int(value)
        let matchLengthText: String
        switch value {
        case 3:
            matchLengthText = "Best-of three sets"
        case 5:
            matchLengthText = "Best-of five sets"
        case 7:
            matchLengthText = "Best-of seven sets"
        default:
            matchLengthText = "One set"
        }
        matchLengthLabel.setText(matchLengthText)
        session.sendMessage(["match length" : ScoreManager.matchLength], replyHandler: nil)
    }
    
    @IBAction func changeSetType(_ value: Bool) {
        switch value {
        case false:
//            DispatchQueue.main.sync {
//                pushController(withName: "Start", context: nil)
//            }
            ScoreManager.setType = .tiebreak
            setTypeSwitch.setTitle("Tiebreaker set")
            session.sendMessage(["set type" : "Tiebreaker set"], replyHandler: nil)
        case true:
            ScoreManager.setType = .advantage
            setTypeSwitch.setTitle("Advantage set")
            session.sendMessage(["set type" : "Advantage set"], replyHandler: nil)
        }
    }
    
    @IBAction func start() {
        print(ScoreManager.matchLength)
        session.sendMessage(["live": ScoreManager.matchLength], replyHandler: nil)
        pushController(withName: "Scoreboard", context: nil)
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.sync {
            switch message {
            case _ where message["match length"] != nil:
                switch message["match length"] as! Int {
                case 3:
                    ScoreManager.matchLength = 3
                    matchLengthLabel.setText("Best-of 3 sets")
                    matchLengthSlider.setValue(3)
                case 5:
                    ScoreManager.matchLength = 5
                    matchLengthLabel.setText("Best-of 5 sets")
                    matchLengthSlider.setValue(5)
                case 7:
                    ScoreManager.matchLength = 7
                    matchLengthLabel.setText("Best-of 7 sets")
                    matchLengthSlider.setValue(7)
                default:
                    ScoreManager.matchLength = 1
                    matchLengthSlider.setValue(1)
                }
            case _ where message["set type"] != nil:
                switch message["set type"] as! String {
                case "Tiebreaker set":
                    ScoreManager.setType = .tiebreak
                    setTypeSwitch.setOn(false)
                case "Advantage set":
                    ScoreManager.setType = .advantage
                    setTypeSwitch.setOn(true)
                default:
                    break
                }
                setTypeSwitch.setTitle(message["set type"] as? String)
            case _ where message["start"] != nil:
                start()
            default:
                break
            }
        }
    }
}

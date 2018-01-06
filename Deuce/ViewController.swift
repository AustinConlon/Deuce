//
//  ViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 11/27/16.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity

class ViewController: UIViewController, WCSessionDelegate  {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    // MARK: Properties
    var session: WCSession!
    
    @IBOutlet weak var changeMatchLengthSegmentedControl: UISegmentedControl!
    @IBOutlet weak var setTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var startNewMatchButton: UIButton!
    @IBOutlet weak var announcementLabel: UILabel!
    
    @IBOutlet weak var leftSideServingStatusLabel: UILabel!
    @IBOutlet weak var leftSideGameScoreButton: UIButton!
    @IBOutlet weak var leftSideSetScoreLabel: UILabel!
    @IBOutlet weak var leftSideMatchScoreLabel: UILabel!
    @IBOutlet weak var leftSideStartsWithPairedWatch: UIButton!
    @IBOutlet weak var leftSideServesFirstButton: UIButton!
    
    @IBOutlet weak var rightSideServingStatusLabel: UILabel!
    @IBOutlet weak var rightSideGameScoreButton: UIButton!
    @IBOutlet weak var rightSideSetScoreLabel: UILabel!
    @IBOutlet weak var rightSideMatchScoreLabel: UILabel!
    @IBOutlet weak var rightSideStartsWithPairedWatch: UIButton!
    @IBOutlet weak var rightSideServesFirstButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        hideServingLabels()
    }
    
    required init(coder aDecoder: NSCoder) {
        // Initialize properties here.
        super.init(coder: aDecoder)!
        if (WCSession.isSupported()) {
            session = WCSession.default()
            session.delegate = self // Conforms to WCSessionDelegate.
            session.activate()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func changeMatchLength(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            ScoreManager.matchLength = 3
        case 2:
            ScoreManager.matchLength = 5
        case 3:
            ScoreManager.matchLength = 7
        default:
            ScoreManager.matchLength = 1
        }
        session?.sendMessage(["match length" : ScoreManager.matchLength], replyHandler: nil)
    }
    
    @IBAction func changeTypeOfSet(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            ScoreManager.setType = .tiebreak
            session?.sendMessage(["set type" : "Tiebreaker set"], replyHandler: nil)
        case 1:
            ScoreManager.setType = .advantage
            session?.sendMessage(["set type" : "Advantage set"], replyHandler: nil)
        default:
            break
        }
    }
    
    @IBAction func startMatch(_ sender: Any) {
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            session.sendMessage(["start" : "new match"], replyHandler: nil)
            if session.isWatchAppInstalled {
                askToSelectStartingSideOfPairedWatch()
                leftSideGameScoreButton.isHidden = true
                rightSideGameScoreButton.isHidden = true
            } else {
                askToSelectStartingServer()
            }
        }
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            askToSelectStartingServer()
        }
        changeMatchLengthSegmentedControl.isHidden = true
        setTypeSegmentedControl.isHidden = true
        startNewMatchButton.isHidden = true
    }
    
    func askToSelectStartingSideOfPairedWatch() {
        announcementLabel.text = "Will the player with the paired Apple Watch start on the left or right side?"
        announcementLabel.isHidden = false
        leftSideStartsWithPairedWatch.isHidden = false
        rightSideStartsWithPairedWatch.isHidden = false
    }
    
    func askToSelectStartingServer() {
        leftSideServesFirstButton.isHidden = false
        rightSideServesFirstButton.isHidden = false
        if ((arc4random_uniform(2)) == 0) {
            announcementLabel.text = "The player starting on the left side won the coin toss. Ask them to choose which player will serve first and then select accordingly."
        } else {
            announcementLabel.text = "The player starting on the right side won the coin toss. Ask them to choose which player will serve first and then select accordingly."
        }
        announcementLabel.isHidden = false
    }
    
    @IBAction func setPlayerWithPairedWatchToStartLeftSide(_ sender: Any) {
        leftSideStartsWithPairedWatch.isHidden = true
        rightSideStartsWithPairedWatch.isHidden = true
        askToSelectStartingServer()
    }
    
    @IBAction func setPlayerWithPairedWatchToStartRightSide(_ sender: Any) {
        leftSideStartsWithPairedWatch.isHidden = true
        rightSideStartsWithPairedWatch.isHidden = true
        askToSelectStartingServer()
    }
    
    @IBAction func setLeftSideToServeFirst(_ sender: Any) {
        session?.sendMessage(["server" : "first player"], replyHandler: nil)
        ScoreManager.server = .first
        updateLabelsForBeginningOfMatch()
    }
    
    @IBAction func setRightSideToServeFirst(_ sender: Any) {
        session?.sendMessage(["server" : "second player"], replyHandler: nil)
        ScoreManager.server = .second
        updateLabelsForBeginningOfMatch()
    }
    
    @IBAction func scorePointForLeftSide(_ sender: Any) {
        playerOne.scorePoint()
        updateLeftSideGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        session?.sendMessage(["scored" : "first player"], replyHandler: nil)
    }
    
    @IBAction func scorePointForRightSide(_ sender: Any) {
        playerTwo.scorePoint()
        updateRightSideGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        session?.sendMessage(["scored" : "second player"], replyHandler: nil)
    }
    
    func updateLeftSideGameScoreLabel() {
        switch (playerOne.gameScore, ScoreManager.isDeuce) {
        case (0, false): // New game
            updateServingLabels()
            resetGameScoreLabels()
        case (15...30, false):
            leftSideGameScoreButton.setTitle(String(playerOne.gameScore), for: .normal)
        case (40, true):
            updateGameScoreLabelsForDeuce()
        case (40, false):
            switch ScoreManager.advantage {
            case .first?:
                switch ScoreManager.server {
                case .first?:
                    leftSideGameScoreButton.setTitle("Ad in", for: .normal)
                case .second?:
                    leftSideGameScoreButton.setTitle("Ad out", for: .normal)
                default:
                    break
                }
                rightSideGameScoreButton.setTitle("🎾", for: .normal)
            default:
                leftSideGameScoreButton.setTitle(String(playerOne.gameScore), for: .normal)
            }
        default:
            break
        }
    }
    
    func updateRightSideGameScoreLabel() {
        switch (playerTwo.gameScore, ScoreManager.isDeuce) {
        case (0, false): // New game
            updateServingLabels()
            resetGameScoreLabels()
        case (15...30, false):
            rightSideGameScoreButton.setTitle(String(playerTwo.gameScore), for: .normal)
        case (40, true):
            updateGameScoreLabelsForDeuce()
        case (40, false):
            switch ScoreManager.advantage {
            case .second?:
                switch ScoreManager.server {
                case .first?:
                    rightSideGameScoreButton.setTitle("Ad out", for: .normal)
                case .second?:
                    rightSideGameScoreButton.setTitle("Ad in", for: .normal)
                default:
                    break
                }
                leftSideGameScoreButton.setTitle("🎾", for: .normal)
            default:
                rightSideGameScoreButton.setTitle(String(playerTwo.gameScore), for: .normal)
            }
        default:
            break
        }
    }
    
    func resetGameScoreLabels() {
        leftSideGameScoreButton.isHidden = false
        rightSideGameScoreButton.isHidden = false
        leftSideGameScoreButton.setTitle("Love", for: .normal)
        rightSideGameScoreButton.setTitle("Love", for: .normal)
    }
    
    func updateGameScoreLabelsForDeuce() {
        leftSideGameScoreButton.setTitle("Deuce", for: .normal)
        rightSideGameScoreButton.setTitle("Deuce", for: .normal)
    }
    
    func updateSetScoreLabels() {
        switch ScoreManager.isInTiebreakGame {
        case true:
            leftSideSetScoreLabel.text = "Tiebreak game"
            rightSideSetScoreLabel.text = "Tiebreak game"
        default:
            leftSideSetScoreLabel.text = "Set score: \(playerOne.setScore)"
            rightSideSetScoreLabel.text = "Set score: \(playerTwo.setScore)"
        }
    }
    
    func updateMatchScoreLabels() {
        leftSideMatchScoreLabel.text = "Match score: \(playerOne.matchScore)"
        rightSideMatchScoreLabel.text = "Match score: \(playerTwo.matchScore)"
        if let _ = ScoreManager.winner {
            updateLabelsForEndOfMatch()
        }
    }
    
    func updateLabelsForEndOfMatch() {
        switch ScoreManager.winner {
        case .first?:
            leftSideGameScoreButton.setTitle("🏆", for: .normal)
            rightSideGameScoreButton.isHidden = true
        case .second?:
            leftSideGameScoreButton.isHidden = true
            rightSideGameScoreButton.setTitle("🏆", for: .normal)
        default:
            break
        }
        leftSideGameScoreButton.isEnabled = false
        rightSideGameScoreButton.isEnabled = false
        hideServingLabels()
    }
    
    func updateServingLabels() {
        switch ScoreManager.server {
        case .first?:
            leftSideServingStatusLabel.isHidden = false
            rightSideServingStatusLabel.isHidden = true
        case .second?:
            leftSideServingStatusLabel.isHidden = true
            rightSideServingStatusLabel.isHidden = false
        default:
            break
        }
    }
    
    func hideServingLabels() {
        leftSideServingStatusLabel.isHidden = true
        rightSideServingStatusLabel.isHidden = true
    }
    
    func updateLabelsForBeginningOfMatch() {
        announcementLabel.isHidden = true
        updateServingLabels()
        leftSideGameScoreButton.isHidden = false
        rightSideGameScoreButton.isHidden = false
        leftSideSetScoreLabel.isHidden = false
        rightSideSetScoreLabel.isHidden = false
        leftSideMatchScoreLabel.isHidden = false
        rightSideMatchScoreLabel.isHidden = false
        leftSideServesFirstButton.isHidden = true
        rightSideServesFirstButton.isHidden = true
    }
    
    // MARK: WatchConnectivity
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.sync {
            switch message {
            case _ where message["match length"] != nil:
                ScoreManager.matchLength = message["match length"] as! Int
                switch ScoreManager.matchLength {
                case 3:
                    changeMatchLengthSegmentedControl.selectedSegmentIndex = 1
                case 5:
                    changeMatchLengthSegmentedControl.selectedSegmentIndex = 2
                case 7:
                    changeMatchLengthSegmentedControl.selectedSegmentIndex = 3
                default:
                    changeMatchLengthSegmentedControl.selectedSegmentIndex = 0
                }
            case _ where message["set type"] != nil:
                switch message["set type"] as! String {
                case "Tiebreaker set":
                    ScoreManager.setType = .tiebreak
                    setTypeSegmentedControl.selectedSegmentIndex = 0
                case "Advantage set":
                    ScoreManager.setType = .advantage
                    setTypeSegmentedControl.selectedSegmentIndex = 1
                default:
                    break
                }
            case _ where message["server"] != nil:
                switch message["server"] as! String {
                case "first player":
                    ScoreManager.server = .first
                case "second player":
                    ScoreManager.server = .second
                default:
                    break
                }
                updateServingLabels()
            case _ where message["scored"] != nil:
                switch message["scored"] as! String {
                case "first player":
                    playerOne.scorePoint()
                    updateLeftSideGameScoreLabel()
                    updateSetScoreLabels()
                    updateMatchScoreLabels()
                    if let _ = ScoreManager.winner {
                        updateLabelsForEndOfMatch()
                    }
                case "second player":
                    playerTwo.scorePoint()
                    updateRightSideGameScoreLabel()
                    updateSetScoreLabels()
                    updateMatchScoreLabels()
                    if let _ = ScoreManager.winner {
                        updateLabelsForEndOfMatch()
                    }
                default:
                    break
                }
            case _ where message["start new match"] != nil:
                ScoreManager.reset()
                resetGameScoreLabels()
                updateSetScoreLabels()
                updateMatchScoreLabels()
            default:
                break
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Begin the activation process for the new Apple Watch.
        session.activate()
    }
}

//
//  ViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 11/27/16.
//  Copyright © 2017 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity
import GoogleMobileAds

class ViewController: UIViewController, WCSessionDelegate  {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    // MARK: Properties
    var session: WCSession!
    
    @IBOutlet weak var matchLengthStepper: UIStepper!
    @IBOutlet weak var matchLengthLabel: UILabel!
    @IBOutlet weak var setTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var playerOneGameScoreLabel: UIButton!
    @IBOutlet weak var playerOneSetScoreLabel: UILabel!
    @IBOutlet weak var playerOneMatchScoreLabel: UILabel!
    @IBOutlet weak var playerOneServingLabel: UILabel!
    
    @IBOutlet weak var playerWithPairedAppleWatchLabel: UILabel!
    @IBOutlet weak var playerTwoGameScoreLabel: UIButton!
    @IBOutlet weak var playerTwoSetScoreLabel: UILabel!
    @IBOutlet weak var playerTwoMatchScoreLabel: UILabel!
    @IBOutlet weak var playerTwoServingLabel: UILabel!
    
    @IBOutlet weak var bannerView: GADBannerView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        hideServingLabels()
        if session?.isReachable == false || UI_USER_INTERFACE_IDIOM() == .pad { // Only Deuce for iPhone is being used
            playerWithPairedAppleWatchLabel.isHidden = true
            ScoreManager.determineWhoServes()
            updateServingLabels()
        }
        bannerView.adSize = kGADAdSizeSmartBannerPortrait
        bannerView.adUnitID = "ca-app-pub-8970886331444312/2500597617"
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
        let request = GADRequest()
        request.testDevices = [ kGADSimulatorID,                      // All simulators
                                "e35b407201643dd0d1e1369739471903"];  // Sample device ID
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

    // Mark: Actions
    @IBAction func changeMatchLength(_ sender: UIStepper) {
        ScoreManager.matchLength = Int(sender.value)
        switch ScoreManager.matchLength {
        case 3:
            matchLengthLabel.text = "Best-of three sets"
        case 5:
            matchLengthLabel.text = "Best-of five sets"
        case 7:
            matchLengthLabel.text = "Best-of seven sets"
        default:
            matchLengthLabel.text = "One set"
        }
        session?.sendMessage(["match length" : ScoreManager.matchLength], replyHandler: nil)
        session?.sendMessage(["match length text" : matchLengthLabel.text as Any], replyHandler: nil)
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
    
    @IBAction func startNewMatch(_ sender: Any) {
        ScoreManager.reset()
        updateLabelsForNewMatch()
        session?.sendMessage(["start new match" : "reset"], replyHandler: nil)
    }
    
    @IBAction func incrementFirstPlayerScore(_ sender: Any) {
        playerOne.scorePoint()
        updateFirstPlayerGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        session?.sendMessage(["scored" : "first player"], replyHandler: nil)
        hideSettingsControls()
    }
    
    @IBAction func incrementSecondPlayerScore(_ sender: Any) {
        playerTwo.scorePoint()
        updateSecondPlayerGameScoreLabel()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        session?.sendMessage(["scored" : "second player"], replyHandler: nil)
        hideSettingsControls()
    }
    
    func updateFirstPlayerGameScoreLabel() {
        switch (playerOne.gameScore, ScoreManager.isDeuce) {
        case (0, false): // New game
            updateServingLabels()
            resetGameScoreLabels()
        case (15...30, false):
            playerOneGameScoreLabel.setTitle(String(playerOne.gameScore), for: .normal)
        case (40, true):
            updateGameScoreLabelsForDeuce()
        case (40, false):
            switch ScoreManager.advantage {
            case .first?:
                switch ScoreManager.server {
                case .first?:
                    playerOneGameScoreLabel.setTitle("Ad in", for: .normal)
                case .second?:
                    playerOneGameScoreLabel.setTitle("Ad out", for: .normal)
                default:
                    break
                }
                playerTwoGameScoreLabel.setTitle("🎾", for: .normal)
            default:
                playerOneGameScoreLabel.setTitle(String(playerOne.gameScore), for: .normal)
            }
        default:
            break
        }
    }
    
    func updateSecondPlayerGameScoreLabel() {
        switch (playerTwo.gameScore, ScoreManager.isDeuce) {
        case (0, false): // New game
            updateServingLabels()
            resetGameScoreLabels()
        case (15...30, false):
            playerTwoGameScoreLabel.setTitle(String(playerTwo.gameScore), for: .normal)
        case (40, true):
            updateGameScoreLabelsForDeuce()
        case (40, false):
            switch ScoreManager.advantage {
            case .second?:
                switch ScoreManager.server {
                case .first?:
                    playerTwoGameScoreLabel.setTitle("Ad out", for: .normal)
                case .second?:
                    playerTwoGameScoreLabel.setTitle("Ad in", for: .normal)
                default:
                    break
                }
                playerOneGameScoreLabel.setTitle("🎾", for: .normal)
            default:
                playerTwoGameScoreLabel.setTitle(String(playerTwo.gameScore), for: .normal)
            }
        default:
            break
        }
    }
    
    func resetGameScoreLabels() {
        playerOneGameScoreLabel.isHidden = false
        playerTwoGameScoreLabel.isHidden = false
        playerOneGameScoreLabel.setTitle("Love", for: .normal)
        playerTwoGameScoreLabel.setTitle("Love", for: .normal)
    }
    
    func updateGameScoreLabelsForDeuce() {
        playerOneGameScoreLabel.setTitle("Deuce", for: .normal)
        playerTwoGameScoreLabel.setTitle("Deuce", for: .normal)
    }
    
    func updateSetScoreLabels() {
        switch ScoreManager.isInTiebreakGame {
        case true:
            playerOneSetScoreLabel.text = "Tiebreak game"
            playerTwoSetScoreLabel.text = "Tiebreak game"
        default:
            playerOneSetScoreLabel.text = "Set score: \(playerOne.setScore)"
            playerTwoSetScoreLabel.text = "Set score: \(playerTwo.setScore)"
        }
    }
    
    func updateMatchScoreLabels() {
        playerOneMatchScoreLabel.text = "Match score: \(playerOne.matchScore)"
        playerTwoMatchScoreLabel.text = "Match score: \(playerTwo.matchScore)"
        if let _ = ScoreManager.winner {
            updateLabelsForEndOfMatch()
        }
    }
    
    func updateLabelsForEndOfMatch() {
        switch ScoreManager.winner {
        case .first?:
            playerOneGameScoreLabel.setTitle("🏆", for: .normal)
            playerTwoGameScoreLabel.isHidden = true
        case .second?:
            playerOneGameScoreLabel.isHidden = true
            playerTwoGameScoreLabel.setTitle("🏆", for: .normal)
        default:
            break
        }
        hideServingLabels()
    }
    
    func updateServingLabels() {
        switch ScoreManager.server {
        case .first?:
            playerOneServingLabel.isHidden = false
            playerTwoServingLabel.isHidden = true
        case .second?:
            playerOneServingLabel.isHidden = true
            playerTwoServingLabel.isHidden = false
        default:
            break
        }
    }
    
    func hideSettingsControls() {
        matchLengthStepper.isHidden = true
        matchLengthLabel.isHidden = true
        setTypeSegmentedControl.isHidden = true
    }
    
    func showSettingsControls() {
        matchLengthStepper.isHidden = false
        matchLengthLabel.isHidden = false
        setTypeSegmentedControl.isHidden = false
    }
    
    func hideServingLabels() {
        playerOneServingLabel.isHidden = true
        playerTwoServingLabel.isHidden = true
    }
    
    func updateLabelsForNewMatch() {
        resetGameScoreLabels()
        updateSetScoreLabels()
        updateMatchScoreLabels()
        if session?.isReachable == false { // Using Deuce without Apple Watch
            ScoreManager.determineWhoServes()
            updateServingLabels()
        }
        showSettingsControls()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.sync {
            switch message {
            case _ where message["match length"] != nil:
                ScoreManager.matchLength = message["match length"] as! Int
                matchLengthStepper.value = message["match length"] as! Double
            case _ where message["match length text"] != nil:
                matchLengthLabel.text = message["match length text"] as? String
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
                    updateFirstPlayerGameScoreLabel()
                    updateSetScoreLabels()
                    updateMatchScoreLabels()
                    if let _ = ScoreManager.winner {
                        updateLabelsForEndOfMatch()
                    }
                    hideSettingsControls()
                case "second player":
                    playerTwo.scorePoint()
                    updateSecondPlayerGameScoreLabel()
                    updateSetScoreLabels()
                    updateMatchScoreLabels()
                    if let _ = ScoreManager.winner {
                        updateLabelsForEndOfMatch()
                    }
                    hideSettingsControls()
                default:
                    break
                }
            case _ where message["new match"] != nil:
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

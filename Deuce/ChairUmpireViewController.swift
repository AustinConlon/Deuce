//
//  ChairUmpireSettingsViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 4/1/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity

class ChairUmpireViewController: UIViewController, WCSessionDelegate  {
    /** Called when the session has completed activation. If session state is WCSessionActivationStateNotActivated there will be an error with more details. */
    @available(iOS 9.3, *)
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    // MARK: Properties
    var session: WCSession!
    var scoreManager: ScoreManager?
    var currentGame: GameManager {
        get {
            return currentSet.currentGame
        }
    }
    var currentSet: SetManager {
        get {
            return scoreManager!.currentMatch.currentSet
        }
    }
    var currentMatch: MatchManager {
        get {
            return scoreManager!.currentMatch
        }
    }
    var maximumNumberOfSetsInMatch = 1 { // Matches are 1 set, best-of 3 sets, or best-of 5 sets.
        didSet {
            switch maximumNumberOfSetsInMatch {
            case 3:
                changeMatchLengthSegmentedControl.selectedSegmentIndex = 1
            case 5:
                changeMatchLengthSegmentedControl.selectedSegmentIndex = 2
            default:
                changeMatchLengthSegmentedControl.selectedSegmentIndex = 0
            }
        }
    }
    var typeOfSet: TypeOfSet = .tiebreak { // Tiebreak sets are more commonly played.
        didSet {
            switch typeOfSet {
            case .advantage:
                setTypeSegmentedControl.selectedSegmentIndex = 1
            default:
                setTypeSegmentedControl.selectedSegmentIndex = 0
            }
        }
    }
    
    @IBOutlet weak var startMatchButton: UIBarButtonItem!
    @IBOutlet weak var endMatchButton: UIBarButtonItem!
    @IBOutlet weak var changeMatchLengthSegmentedControl: UISegmentedControl!
    @IBOutlet weak var setTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var leftSideServingStatusLabel: UILabel!
    @IBOutlet weak var leftSideGameScoreButton: UIButton!
    @IBOutlet weak var leftSideSetScoreLabel: UILabel!
    @IBOutlet weak var leftSideMatchScoreLabel: UILabel!
    @IBOutlet weak var leftSideStartsWithPairedWatch: UIButton!
    
    @IBOutlet weak var rightSideServingStatusLabel: UILabel!
    @IBOutlet weak var rightSideGameScoreButton: UIButton!
    @IBOutlet weak var rightSideSetScoreLabel: UILabel!
    @IBOutlet weak var rightSideMatchScoreLabel: UILabel!
    @IBOutlet weak var rightSideStartsWithPairedWatch: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if !session.isPaired {
            changeMatchLengthSegmentedControl.isHidden = false
            setTypeSegmentedControl.isHidden = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if session.isPaired {
            startMatchButton.isEnabled = false
            let alert = UIAlertController(title: "Start from Apple Watch", message: "To start, open Deuce on Apple Watch and then press the Start button.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            self.present(alert, animated: true, completion: nil)
        }
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
            maximumNumberOfSetsInMatch = 3
        case 2:
            maximumNumberOfSetsInMatch = 5
        default:
            maximumNumberOfSetsInMatch = 1
        }
        session?.sendMessage(["match length" : maximumNumberOfSetsInMatch], replyHandler: nil)
    }
    
    @IBAction func changeTypeOfSet(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            typeOfSet = .tiebreak
            session?.sendMessage(["type of set" : "tiebreak"], replyHandler: nil)
        case 1:
            typeOfSet = .advantage
            session?.sendMessage(["type of set" : "advantage"], replyHandler: nil)
        default:
            break
        }
    }
    
    @IBAction func startMatch(_ sender: Any) {
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            session.sendMessage(["start" : "new match"], replyHandler: nil)
            if session.isWatchAppInstalled {
                leftSideGameScoreButton.isHidden = true
                rightSideGameScoreButton.isHidden = true
            } else {
                askToSelectStartingServer()
            }
        }
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            askToSelectStartingServer()
        }
    }
    
    @IBAction func stopMatch(_ sender: Any) {
        updateLabelsForEndOfMatch()
    }
    
    @IBAction func scorePointForLeftSide(_ sender: Any) {
        currentMatch.scorePointForPlayerOneInCurrentGame()
        updateLabelsFromModel()
        session?.sendMessage(["scored" : "first player"], replyHandler: nil)
    }
    
    @IBAction func scorePointForRightSide(_ sender: Any) {
        currentMatch.scorePointForPlayerTwoInCurrentGame()
        updateLabelsFromModel()
        session?.sendMessage(["scored" : "second player"], replyHandler: nil)
    }
    
    func askToSelectStartingServer() {
        let coinTossResult: String
        if ((arc4random_uniform(2)) == 0) {
            coinTossResult = "The player starting on your left side won the coin toss. Select their choice of who will serve first."
        } else {
            coinTossResult = "The player starting on your right side won the coin toss. Select their choice of who will serve first."
        }
        let alert = UIAlertController(title: "Coin Toss", message: coinTossResult, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Left Player", style: .default, handler: { _ in
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, playerThatWillServeFirst: .one)
            self.scoreManager = ScoreManager(match)
            self.startScoring()
        }))
        alert.addAction(UIAlertAction(title: "Right Player", style: .default, handler: { _ in
            let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, playerThatWillServeFirst: .two)
            self.scoreManager = ScoreManager(match)
            self.startScoring()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startScoring() {
        changeMatchLengthSegmentedControl.isHidden = true
        setTypeSegmentedControl.isHidden = true
        startMatchButton.isEnabled = false
        endMatchButton.isEnabled = true
        updateLabelsFromModel()
        leftSideGameScoreButton.isEnabled = true
        leftSideGameScoreButton.isHidden = false
        leftSideSetScoreLabel.isHidden = false
        leftSideMatchScoreLabel.isHidden = false
        rightSideGameScoreButton.isEnabled = true
        rightSideGameScoreButton.isHidden = false
        rightSideSetScoreLabel.isHidden = false
        rightSideMatchScoreLabel.isHidden = false
        let server = (scoreManager?.currentMatch.currentSet.currentGame.server)!
        switch server {
        case .one:
            leftSideServingStatusLabel.isHidden = false
        case .two:
            rightSideServingStatusLabel.isHidden = false
        }
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateGameScoresFromModel()
        updateSetScoresFromModel()
        updateMatchScoresFromModel()
        if let winner = currentMatch.winner {
            switch winner {
            case .one:
                leftSideGameScoreButton.setTitle("🏆", for: .normal)
                rightSideGameScoreButton.isHidden = true
            case .two:
                leftSideGameScoreButton.isHidden = true
                rightSideGameScoreButton.setTitle("🏆", for: .normal)
            }
            leftSideServingStatusLabel.isHidden = true
            rightSideServingStatusLabel.isHidden = true
            leftSideGameScoreButton.isEnabled = false
            rightSideGameScoreButton.isEnabled = false
            endMatchButton.style = .done
        }
    }
    
    func updateLabelsForEndOfMatch() {
        endMatchButton.isEnabled = false
        startMatchButton.isEnabled = true
        changeMatchLengthSegmentedControl.isHidden = false
        setTypeSegmentedControl.isHidden = false
        leftSideServingStatusLabel.isHidden = true
        leftSideGameScoreButton.isHidden = true
        leftSideSetScoreLabel.isHidden = true
        leftSideMatchScoreLabel.isHidden = true
        rightSideServingStatusLabel.isHidden = true
        rightSideGameScoreButton.isHidden = true
        rightSideSetScoreLabel.isHidden = true
        rightSideMatchScoreLabel.isHidden = true
    }
    
    func updateServingLabelsFromModel() {
        let newServer = currentGame.server
        switch newServer! {
        case .one:
            leftSideServingStatusLabel.isHidden = false
            rightSideServingStatusLabel.isHidden = true
        case .two:
            leftSideServingStatusLabel.isHidden = true
            rightSideServingStatusLabel.isHidden = false
        }
    }
    
    func updateGameScoresFromModel() {
        switch currentGame.isTiebreaker {
        case true:
            leftSideGameScoreButton.setTitle(String(currentGame.playerOneGameScore), for: .normal)
            rightSideGameScoreButton.setTitle(String(currentGame.playerTwoGameScore), for: .normal)
        default:
            updatePlayerOneGameScoreFromModel()
            updatePlayerTwoGameScoreFromModel()
        }
    }
    
    func updatePlayerOneGameScoreFromModel() {
        switch currentGame.playerOneGameScore {
        case 0:
            leftSideGameScoreButton.setTitle("Love", for: .normal)
        case 15, 30:
            leftSideGameScoreButton.setTitle(String(currentGame.playerOneGameScore), for: .normal)
        case 40:
            if currentGame.playerTwoGameScore < 40 {
                leftSideGameScoreButton.setTitle(String(currentGame.playerOneGameScore), for: .normal)
            } else if currentGame.playerTwoGameScore == 40 {
                leftSideGameScoreButton.setTitle("Deuce", for: .normal)
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerOneGameScore == currentGame.playerTwoGameScore + 1 {
                if currentGame.server == .one {
                    leftSideGameScoreButton.setTitle("Ad in", for: .normal)
                    rightSideGameScoreButton.setTitle("🎾", for: .normal)
                } else if currentGame.server == .two {
                    leftSideGameScoreButton.setTitle("Ad out", for: .normal)
                    rightSideGameScoreButton.setTitle("🎾", for: .normal)
                }
            } else if currentGame.playerOneGameScore == currentGame.playerTwoGameScore {
                leftSideGameScoreButton.setTitle("Deuce", for: .normal)
            }
        }
    }
    
    func updatePlayerTwoGameScoreFromModel() {
        switch currentGame.playerTwoGameScore {
        case 0:
            rightSideGameScoreButton.setTitle("Love", for: .normal)
        case 15, 30:
            rightSideGameScoreButton.setTitle(String(currentGame.playerTwoGameScore), for: .normal)
        case 40:
            if currentGame.playerOneGameScore < 40 {
                rightSideGameScoreButton.setTitle(String(currentGame.playerTwoGameScore), for: .normal)
            } else if currentGame.playerOneGameScore == 40 {
                rightSideGameScoreButton.setTitle("Deuce", for: .normal)
            }
        default: // Alternating advantage and deuce situations.
            if currentGame.playerTwoGameScore == currentGame.playerOneGameScore + 1 {
                if currentGame.server == .two {
                    leftSideGameScoreButton.setTitle("🎾", for: .normal)
                    rightSideGameScoreButton.setTitle("Ad in", for: .normal)
                } else if currentGame.server == .one {
                    leftSideGameScoreButton.setTitle("🎾", for: .normal)
                    rightSideGameScoreButton.setTitle("Ad out", for: .normal)
                }
            } else if currentGame.playerTwoGameScore == currentGame.playerOneGameScore {
                rightSideGameScoreButton.setTitle("Deuce", for: .normal)
            }
        }
    }
    
    func updateSetScoresFromModel() {
        leftSideSetScoreLabel.text = "Set score: \(currentSet.playerOneSetScore)"
        rightSideSetScoreLabel.text = "Set score: \(currentSet.playerTwoSetScore)"
    }
    
    func updateMatchScoresFromModel() {
        leftSideMatchScoreLabel.text = "Match score: \(currentMatch.playerOneMatchScore)"
        rightSideMatchScoreLabel.text = "Match score: \(currentMatch.playerTwoMatchScore)"
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let maximumNumberOfSetsInMatch = message["match length"] {
                self.maximumNumberOfSetsInMatch = maximumNumberOfSetsInMatch as! Int
            } else if let typeOfSet = message["type of set"] {
                switch typeOfSet as! String {
                case "advantage":
                    self.typeOfSet = .advantage
                    self.setTypeSegmentedControl.selectedSegmentIndex = 1
                default:
                    self.typeOfSet = .tiebreak
                    self.setTypeSegmentedControl.selectedSegmentIndex = 0
                }
            } else if let firstServer = message["first server"] {
                switch firstServer as! String {
                case "player one":
                    let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, playerThatWillServeFirst: .one)
                    self.scoreManager = ScoreManager(match)
                case "player two":
                    let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, playerThatWillServeFirst: .two)
                    self.scoreManager = ScoreManager(match)
                default:
                    break
                }
            } else if message["start"] != nil {
                self.startScoring()
            } else if let scorePoint = message["score point"] {
                switch scorePoint as! String {
                case "player one":
                    self.currentMatch.scorePointForPlayerOneInCurrentGame()
                    self.updateLabelsFromModel()
                case "player two":
                    self.currentMatch.scorePointForPlayerTwoInCurrentGame()
                    self.updateLabelsFromModel()
                default:
                    break
                }
            } else if message["end match"] != nil {
                self.updateLabelsForEndOfMatch()
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

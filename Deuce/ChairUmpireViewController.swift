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
    
    var playerThatWillServeFirst: Player?
    
    // Properties for displaying the score to be easily read in the navigation bar.
    var serverScore: String {
        get {
            if currentGame.server == Player.one {
                return playerOneGameScore
            } else {
                return playerTwoGameScore
            }
        }
    }
    
    var receiverScore: String {
        get {
            if currentGame.server == Player.one {
                return playerTwoGameScore
            } else {
                return playerOneGameScore
            }
        }
    }
    
    var playerOneGameScore: String {
        get {
            switch currentGame.isTiebreaker {
            case true:
                return String(currentGame.playerOneGameScore)
            default:
                switch currentGame.playerOneGameScore {
                case 0:
                    return "Love"
                case 15, 30:
                    return String(currentGame.playerOneGameScore)
                case 40:
                    if currentGame.playerTwoGameScore < 40 {
                        return String(currentGame.playerOneGameScore)
                    } else if currentGame.playerTwoGameScore == 40 {
                        return "Deuce"
                    }
                default: // Alternating advantage and deuce situations.
                    if currentGame.playerOneGameScore == currentGame.playerTwoGameScore + 1 {
                        if currentGame.server == .one {
                            return "Ad in"
                        } else if currentGame.server == .two {
                            return "Ad out"
                        }
                    } else if currentGame.playerOneGameScore == currentGame.playerTwoGameScore {
                        return "Deuce"
                    }
                }
            }
            return ""
        }
    }
    
    var playerTwoGameScore: String {
        switch currentGame.isTiebreaker {
        case true:
            return String(currentGame.playerTwoGameScore)
        default:
            switch currentGame.playerTwoGameScore {
            case 0:
                return "Love"
            case 15, 30:
                return String(currentGame.playerTwoGameScore)
            case 40:
                if currentGame.playerOneGameScore < 40 {
                    return String(currentGame.playerTwoGameScore)
                } else if currentGame.playerOneGameScore == 40 {
                    return "Deuce"
                }
            default: // Alternating advantage and deuce situations.
                if currentGame.playerTwoGameScore == currentGame.playerOneGameScore + 1 {
                    if currentGame.server == .two {
                        return "Ad in"
                    } else if currentGame.server == .one {
                        return "Ad out"
                    }
                } else if currentGame.playerTwoGameScore == currentGame.playerOneGameScore {
                    return "Deuce"
                }
            }
        }
        return ""
    }
    
    @IBOutlet weak var startMatchButton: UIBarButtonItem!
    @IBOutlet weak var endMatchButton: UIBarButtonItem!
    @IBOutlet weak var changeMatchLengthSegmentedControl: UISegmentedControl!
    @IBOutlet weak var setTypeSegmentedControl: UISegmentedControl!
    
    @IBOutlet weak var pairedAppleWatchLabel: UILabel!
    @IBOutlet weak var leftSideServingStatusLabel: UILabel!
    @IBOutlet weak var leftSideGameScoreButton: UIButton!
    @IBOutlet weak var leftSideSetScoreLabel: UILabel!
    @IBOutlet weak var leftSideMatchScoreLabel: UILabel!
    
    @IBOutlet weak var rightSideServingStatusLabel: UILabel!
    @IBOutlet weak var rightSideGameScoreButton: UIButton!
    @IBOutlet weak var rightSideSetScoreLabel: UILabel!
    @IBOutlet weak var rightSideMatchScoreLabel: UILabel!
    
    override func viewDidAppear(_ animated: Bool) {
        if session.isWatchAppInstalled {
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
            session.delegate = self
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
        if session.isReachable {
            session.sendMessage(["match length" : maximumNumberOfSetsInMatch], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
        } else {
            do {
                try session.updateApplicationContext(["match length" : maximumNumberOfSetsInMatch])
            } catch {
                print(error)
            }
        }
    }
    
    @IBAction func changeTypeOfSet(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            typeOfSet = .tiebreak
            if session.isReachable {
                session.sendMessage(["type of set" : "tiebreak"], replyHandler: nil, errorHandler: { Error in
                    print(Error)
                })
            } else {
                do {
                    try session.updateApplicationContext(["type of set" : "tiebreak"])
                } catch {
                    print(error)
                }
            }
        case 1:
            typeOfSet = .advantage
            if session.isReachable {
                session.sendMessage(["type of set" : "advantage"], replyHandler: nil, errorHandler: { Error in
                    print(Error)
                })
            } else {
                do {
                    try session.updateApplicationContext(["type of set" : "advantage"])
                } catch {
                    print(error)
                }
            }
        default:
            break
        }
    }
    
    @IBAction func startMatch(_ sender: Any) {
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            if session.isReachable {
                session.sendMessage(["start" : "new match"], replyHandler: nil, errorHandler: { Error in
                    print(Error)
                })
            } else {
                do {
                    try session.updateApplicationContext(["start" : "new match"])
                } catch {
                    print(error)
                }
            }
            if session.isWatchAppInstalled {
                leftSideGameScoreButton.isHidden = true
                rightSideGameScoreButton.isHidden = true
            } else {
                coinToss()
            }
        }
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            coinToss()
        }
    }
    
    @IBAction func stopMatch(_ sender: Any) {
        if currentMatch.matchEnded == false {
            let alert = UIAlertController(title: "End Match", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel action"), style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .destructive, handler: { _ in
                if self.session.isReachable {
                    self.session.sendMessage(["end match" : "reset"], replyHandler: nil, errorHandler: { Error in
                        print(Error)
                    })
                } else {
                    do {
                        try self.session.updateApplicationContext(["end match" : "reset"])
                    } catch {
                        print(error)
                    }
                }
                self.updateLabelsForEndOfMatch()
            }))
            self.present(alert, animated: true, completion: nil)
        } else {
            updateLabelsForEndOfMatch()
        }
    }
    
    @IBAction func scorePointForPlayerOne(_ sender: Any) {
        if session.isReachable {
            session.sendMessage(["score point" : "player one"], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
        } else {
            do {
                try session.updateApplicationContext(["score point" : "player one"])
            } catch {
                print(error)
            }
        }
        currentMatch.scorePointForPlayerOneInCurrentGame()
        updateLabelsFromModel()
    }
    
    @IBAction func scorePointForPlayerTwo(_ sender: Any) {
        if session.isReachable {
            session.sendMessage(["score point" : "player two"], replyHandler: nil, errorHandler: { Error in
                print(Error)
            })
        } else {
            do {
                try session.updateApplicationContext(["score point" : "player two"])
            } catch {
                print(error)
            }
        }
        currentMatch.scorePointForPlayerTwoInCurrentGame()
        updateLabelsFromModel()
    }
    
    func coinToss() {
        let coinTossResult: String
        if ((arc4random_uniform(2)) == 0) {
            coinTossResult = "The player starting on your left side won the coin toss. Select their choice of who will serve first."
        } else {
            coinTossResult = "The player starting on your right side won the coin toss. Select their choice of who will serve first."
        }
        let alert = UIAlertController(title: "Coin Toss", message: coinTossResult, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Left Player", style: .default, handler: { _ in
            self.playerThatWillServeFirst = .one
            self.startScoring()
        }))
        alert.addAction(UIAlertAction(title: "Right Player", style: .default, handler: { _ in
            self.playerThatWillServeFirst = .two
            self.startScoring()
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func startScoring() {
        let match = MatchManager(self.maximumNumberOfSetsInMatch, self.typeOfSet, self.playerThatWillServeFirst!)
        self.scoreManager = ScoreManager(match)
        updateLabelsFromModel()
        changeMatchLengthSegmentedControl.isHidden = true
        setTypeSegmentedControl.isHidden = true
        startMatchButton.isEnabled = false
        endMatchButton.isEnabled = true
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
        if session.isWatchAppInstalled {
            pairedAppleWatchLabel.isHidden = false
        }
    }
    
    func updateLabelsFromModel() {
        updateServingLabelsFromModel()
        updateNavigationBarGameScoreFromModel()
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
        pairedAppleWatchLabel.isHidden = true
        title = "Chair Umpire"
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
    
    func updateNavigationBarGameScoreFromModel() {
        if serverScore == "Deuce" {
            title = "Deuce"
        } else if serverScore == "Ad in" || receiverScore == "Ad in" {
            title = "Advantage in"
        } else if serverScore == "Ad out" || receiverScore == "Ad out" {
            title = "Advantage out"
        } else {
            if currentMatch.winner == nil {
                title = "\(serverScore)-\(receiverScore)"
            } else {
                title = "Winner"
            }
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
        if playerTwoGameScore == "Ad in" || playerTwoGameScore == "Ad out" {
            leftSideGameScoreButton.setTitle("🎾", for: .normal)
        } else {
            leftSideGameScoreButton.setTitle(playerOneGameScore, for: .normal)
        }
    }
    
    func updatePlayerTwoGameScoreFromModel() {
        if playerOneGameScore == "Ad in" || playerOneGameScore == "Ad out" {
            rightSideGameScoreButton.setTitle("🎾", for: .normal)
        } else {
            rightSideGameScoreButton.setTitle(playerTwoGameScore, for: .normal)
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
                    self.playerThatWillServeFirst = .one
                case "player two":
                    self.playerThatWillServeFirst = .two
                default:
                    break
                }
            } else if message["start"] != nil {
                self.leftSideGameScoreButton.setTitleColor(UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1.0), for: .normal)
                self.rightSideGameScoreButton.setTitleColor(UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 1.0), for: .normal)
                self.startScoring()
            } else if let scorePoint = message["score point"] {
                switch scorePoint as! String {
                case "player one":
                    self.currentMatch.scorePointForPlayerOneInCurrentGame()
                case "player two":
                    self.currentMatch.scorePointForPlayerTwoInCurrentGame()
                default:
                    break
                }
                self.updateLabelsFromModel()
            } else if message["end match"] != nil {
                self.updateLabelsForEndOfMatch()
                self.startMatchButton.isEnabled = false
                self.title = "Chair Umpire"
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

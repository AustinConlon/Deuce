//
//  MatchHistoryTableViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 7/3/18.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity
import os.log
import StoreKit
import HealthKit
import WebKit
import SafariServices

class MatchHistoryTableViewController: UITableViewController, WCSessionDelegate, WKUIDelegate {
    // MARK: Properties
    var session: WCSession!
    
    var matches = [Match]()
    
    var webView: WKWebView!
    
    required init(coder aDecoder: NSCoder) {
        // Initialize properties here.
        super.init(coder: aDecoder)!
        
        if (WCSession.isSupported()) {
            session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let localizedChairUmpireTitle = NSLocalizedString("Chair Umpire", tableName: "Main", comment: "Bar button for presenting the chair umpire view.")
        
        if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone {
            if session.isPaired == false && session.isWatchAppInstalled == false {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: localizedChairUmpireTitle, style: .plain, target: self, action: #selector(presentChairUmpireViewController))
            }
        } else if UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: localizedChairUmpireTitle, style: .plain, target: self, action: #selector(presentChairUmpireViewController))
        }
        
        // Enable self sizing rows.
        tableView.estimatedRowHeight = UITableView.automaticDimension
        tableView.rowHeight = UITableView.automaticDimension
        
        if let savedMatches = loadMatches() {
            matches += savedMatches
//            if #available(iOS 10.3, *) { SKStoreReviewController.requestReview() }
        }
    }
    
    @objc func presentChairUmpireViewController() {
        let chairUmpireViewController = self.storyboard?.instantiateViewController(withIdentifier: "ChairUmpireViewController") as! ChairUmpireViewController
        self.navigationController?.pushViewController(chairUmpireViewController, animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "MatchHistoryTableViewCell", for: indexPath) as? MatchHistoryTableViewCell else {
            fatalError("The dequeued cell is not an instance of MatchHistoryTableViewCell.")
        }

        // Fetch the appropriate match for the data source layout.
        let match = matches[indexPath.row]
        updateMatchHistoryTableViewCell(for: cell, with: match)

        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            matches.remove(at: indexPath.row)
            saveMatches()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func updateMatchHistoryTableViewCell(for cell: MatchHistoryTableViewCell, with match: Match) {
        switch match.sets.count {
        case 0, 1:
            updateLabelsForSetOne(cell, match)
        case 2:
            updateLabelsForSetTwo(cell, match)
        case 3:
            updateLabelsForSetThree(cell, match)
        case 4:
            updateLabelsForSetFour(cell, match)
        case 5:
            updateLabelsForSetFive(cell, match)
        default:
            break
        }
        
        hideMostRecentColumnAfterUndo(cell, match)
        
        switch match.matchWinner {
        case "player one":
            cell.playerOneNameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnOnePlayerOneSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnTwoPlayerOneSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnThreePlayerOneSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnFourPlayerOneSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnFivePlayerOneSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.matchStateLabel.text = "Final"
        case "player two":
            cell.playerTwoNameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnOnePlayerTwoSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnTwoPlayerTwoSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnThreePlayerTwoSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnFourPlayerTwoSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.columnFivePlayerTwoSetScoreLabel.font = UIFont.preferredFont(forTextStyle: .headline)
            cell.matchStateLabel.text = "Final"
        case "none":
            cell.matchStateLabel.isHidden = true
        case .none:
            break
        case .some(_):
            break
        }
    }
    
    func updateLabelsForSetOne(_ cell: MatchHistoryTableViewCell, _ match: Match) {
        cell.columnFiveSetLabel.text = "1"
        cell.columnFivePlayerOneSetScoreLabel.text = String(match.sets[0].playerOneSetScore)
        cell.columnFivePlayerTwoSetScoreLabel.text = String(match.sets[0].playerTwoSetScore)
        
        cell.matchStateLabel.isHidden = false
        cell.columnFiveSetLabel.isHidden = false
        cell.columnFivePlayerOneSetScoreLabel.isHidden = false
        cell.columnFivePlayerTwoSetScoreLabel.isHidden = false
    }
    
    func updateLabelsForSetTwo(_ cell: MatchHistoryTableViewCell, _ match: Match) {
        cell.columnFourSetLabel.text = "1"
        cell.columnFourPlayerOneSetScoreLabel.text = String(match.sets[0].playerOneSetScore)
        cell.columnFourPlayerTwoSetScoreLabel.text = String(match.sets[0].playerTwoSetScore)
        
        cell.columnFiveSetLabel.text = "2"
        cell.columnFivePlayerOneSetScoreLabel.text = String(match.sets[1].playerOneSetScore)
        cell.columnFivePlayerTwoSetScoreLabel.text = String(match.sets[1].playerTwoSetScore)
        
        cell.columnFourSetLabel.isHidden = false
        cell.columnFourPlayerOneSetScoreLabel.isHidden = false
        cell.columnFourPlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnFiveSetLabel.isHidden = false
        cell.columnFivePlayerOneSetScoreLabel.isHidden = false
        cell.columnFivePlayerTwoSetScoreLabel.isHidden = false
    }
    
    func updateLabelsForSetThree(_ cell: MatchHistoryTableViewCell, _ match: Match) {
        cell.columnThreeSetLabel.text = "1"
        cell.columnThreePlayerOneSetScoreLabel.text = String(match.sets[0].playerOneSetScore)
        cell.columnThreePlayerTwoSetScoreLabel.text = String(match.sets[0].playerTwoSetScore)
        
        cell.columnFourSetLabel.text = "2"
        cell.columnFourPlayerOneSetScoreLabel.text = String(match.sets[1].playerOneSetScore)
        cell.columnFourPlayerTwoSetScoreLabel.text = String(match.sets[1].playerTwoSetScore)
        
        cell.columnFiveSetLabel.text = "3"
        cell.columnFivePlayerOneSetScoreLabel.text = String(match.sets[2].playerOneSetScore)
        cell.columnFivePlayerTwoSetScoreLabel.text = String(match.sets[2].playerTwoSetScore)
        
        cell.columnThreeSetLabel.isHidden = false
        cell.columnThreePlayerOneSetScoreLabel.isHidden = false
        cell.columnThreePlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnFourSetLabel.isHidden = false
        cell.columnFourPlayerOneSetScoreLabel.isHidden = false
        cell.columnFourPlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnFiveSetLabel.isHidden = false
        cell.columnFivePlayerOneSetScoreLabel.isHidden = false
        cell.columnFivePlayerTwoSetScoreLabel.isHidden = false
    }
    
    func updateLabelsForSetFour(_ cell: MatchHistoryTableViewCell, _ match: Match) {
        cell.columnTwoSetLabel.text = "1"
        cell.columnTwoPlayerOneSetScoreLabel.text = String(match.sets[0].playerOneSetScore)
        cell.columnTwoPlayerTwoSetScoreLabel.text = String(match.sets[0].playerTwoSetScore)
        
        cell.columnThreeSetLabel.text = "2"
        cell.columnThreePlayerOneSetScoreLabel.text = String(match.sets[1].playerOneSetScore)
        cell.columnThreePlayerTwoSetScoreLabel.text = String(match.sets[1].playerTwoSetScore)
        
        cell.columnFourSetLabel.text = "3"
        cell.columnFourPlayerOneSetScoreLabel.text = String(match.sets[2].playerOneSetScore)
        cell.columnFourPlayerTwoSetScoreLabel.text = String(match.sets[2].playerTwoSetScore)
        
        cell.columnFiveSetLabel.text = "4"
        cell.columnFivePlayerOneSetScoreLabel.text = String(match.sets[3].playerOneSetScore)
        cell.columnFivePlayerTwoSetScoreLabel.text = String(match.sets[3].playerTwoSetScore)
        
        cell.columnTwoSetLabel.isHidden = false
        cell.columnTwoPlayerOneSetScoreLabel.isHidden = false
        cell.columnTwoPlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnThreeSetLabel.isHidden = false
        cell.columnThreePlayerOneSetScoreLabel.isHidden = false
        cell.columnThreePlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnFourSetLabel.isHidden = false
        cell.columnFourPlayerOneSetScoreLabel.isHidden = false
        cell.columnFourPlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnFiveSetLabel.isHidden = false
        cell.columnFivePlayerOneSetScoreLabel.isHidden = false
        cell.columnFivePlayerTwoSetScoreLabel.isHidden = false
    }
    
    func updateLabelsForSetFive(_ cell: MatchHistoryTableViewCell, _ match: Match) {
        cell.columnOneSetLabel.text = "1"
        cell.columnOnePlayerOneSetScoreLabel.text = String(match.sets[0].playerOneSetScore)
        cell.columnOnePlayerTwoSetScoreLabel.text = String(match.sets[0].playerTwoSetScore)
        
        cell.columnTwoSetLabel.text = "2"
        cell.columnTwoPlayerOneSetScoreLabel.text = String(match.sets[1].playerOneSetScore)
        cell.columnTwoPlayerTwoSetScoreLabel.text = String(match.sets[1].playerTwoSetScore)
        
        cell.columnThreeSetLabel.text = "3"
        cell.columnThreePlayerOneSetScoreLabel.text = String(match.sets[2].playerOneSetScore)
        cell.columnThreePlayerTwoSetScoreLabel.text = String(match.sets[2].playerTwoSetScore)
        
        cell.columnFourSetLabel.text = "4"
        cell.columnFourPlayerOneSetScoreLabel.text = String(match.sets[3].playerOneSetScore)
        cell.columnFourPlayerTwoSetScoreLabel.text = String(match.sets[3].playerTwoSetScore)
        
        cell.columnFiveSetLabel.text = "5"
        cell.columnFivePlayerOneSetScoreLabel.text = String(match.sets[4].playerOneSetScore)
        cell.columnFivePlayerTwoSetScoreLabel.text = String(match.sets[4].playerTwoSetScore)
        
        cell.columnOneSetLabel.isHidden = false
        cell.columnOnePlayerOneSetScoreLabel.isHidden = false
        cell.columnOnePlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnTwoSetLabel.isHidden = false
        cell.columnTwoPlayerOneSetScoreLabel.isHidden = false
        cell.columnTwoPlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnThreeSetLabel.isHidden = false
        cell.columnThreePlayerOneSetScoreLabel.isHidden = false
        cell.columnThreePlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnFourSetLabel.isHidden = false
        cell.columnFourPlayerOneSetScoreLabel.isHidden = false
        cell.columnFourPlayerTwoSetScoreLabel.isHidden = false
        
        cell.columnFiveSetLabel.isHidden = false
        cell.columnFivePlayerOneSetScoreLabel.isHidden = false
        cell.columnFivePlayerTwoSetScoreLabel.isHidden = false
    }
    
    func hideMostRecentColumnAfterUndo(_ cell: MatchHistoryTableViewCell, _ match: Match) {
        switch match.sets.count {
        case 1:
            cell.columnFourSetLabel.isHidden = true
            cell.columnFourPlayerOneSetScoreLabel.isHidden = true
            cell.columnFourPlayerTwoSetScoreLabel.isHidden = true
        case 2:
            cell.columnThreeSetLabel.isHidden = true
            cell.columnThreePlayerOneSetScoreLabel.isHidden = true
            cell.columnThreePlayerTwoSetScoreLabel.isHidden = true
        case 3:
            cell.columnTwoSetLabel.isHidden = true
            cell.columnTwoPlayerOneSetScoreLabel.isHidden = true
            cell.columnTwoPlayerTwoSetScoreLabel.isHidden = true
        case 4:
            cell.columnOneSetLabel.isHidden = true
            cell.columnOnePlayerOneSetScoreLabel.isHidden = true
            cell.columnOnePlayerTwoSetScoreLabel.isHidden = true
        default:
            break
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            if applicationContext["start new match"] != nil {
                let newIndexPath = IndexPath(row: self.matches.count, section: 0)
                self.matches.append(Match())
                self.matches.last?.sets.append(SetScore())
                self.tableView.insertRows(at: [newIndexPath], with: .automatic)
                self.saveMatches()
            } else if let sets = applicationContext["sets"] as? [[Int]] {
                self.matches.last?.sets.removeAll()
                
                for set in 0..<sets.count {
                    self.matches.last?.sets.append(SetScore())
                    self.matches.last?.sets[set].playerOneSetScore = sets[set][0]
                    self.matches.last?.sets[set].playerTwoSetScore = sets[set][1]
                }
                self.tableView.reloadData()
                self.saveMatches()
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        DispatchQueue.main.async {
            if let winnerOfCurrentMatch = userInfo["winner"] as? String {
                switch winnerOfCurrentMatch {
                case "player two":
                    self.matches.last?.matchWinner = "player two"
                case "player one":
                    self.matches.last?.matchWinner = "player one"
                case "none":
                    self.matches.last?.matchWinner = "none"
                default:
                    break
                }
                self.tableView.reloadData()
                self.saveMatches()
            }
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
    
    func sessionDidBecomeInactive(_ session: WCSession) { }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Begin the activation process for the new Apple Watch.
        session.activate()
    }
    
    private func saveMatches() {
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(matches, toFile: Match.ArchiveURL.path)
        if isSuccessfulSave {
            os_log("Matches successfully saved.", log: OSLog.default, type: .debug)
        } else {
            os_log("Failed to save matches...", log: OSLog.default, type: .error)
        }
    }
    
    private func loadMatches() -> [Match]?  {
        return NSKeyedUnarchiver.unarchiveObject(withFile: Match.ArchiveURL.path) as? [Match]
    }
    
    @IBAction func showScoringRules(_ sender: Any) {
        var myURL: URL
        if Locale.current.languageCode == "fr" {
            myURL = URL(string:"http://mobile.fft.fr/sites/default/files/pdf/regles_du_jeu_2018.pdf")!
        } else {
            myURL = URL(string:"https://wikipedia.org/wiki/Tennis_scoring_system")!
        }
        let viewController = SFSafariViewController(url: myURL)
        present(viewController, animated: true, completion: nil)
    }
}

//
//  MatchHistoryTableViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 5/23/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity
import os.log
import CloudKit

class MatchHistoryTableViewController: UITableViewController, WCSessionDelegate {
    // MARK: - Properties
    
    var matches = [Match]()
    
    var session: WCSession?
    
    let database = CKContainer(identifier: "iCloud.com.example.Deuce.watchkitapp.watchkitextension").privateCloudDatabase
    
    var matchRecord: CKRecord!
    
    var records = [CKRecord]() {
        didSet {
            if !records.isEmpty {
                matches.removeAll()
                
                for record in records {
                    let matchData = record["matchData"] as! Data
                    let propertyListDecoder = PropertyListDecoder()
                    if let match = try? propertyListDecoder.decode(Match.self, from: matchData) {
                        matches.append(match)
                    }
                }
            }
        }
    }
    
    let propertyListDecoder = PropertyListDecoder()
    
    var becomeActiveObserver: NSObjectProtocol?
    var didFinishLaunchingObserver: NSObjectProtocol?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        configureRefreshControl()
        
        addObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        if let becomeActiveObserver = self.becomeActiveObserver {
            NotificationCenter.default.removeObserver(becomeActiveObserver)
        }
    }
    
    fileprivate func addObservers() {
        becomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { notification in
            self.fetchMatches()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        matches.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MatchHistoryTableViewCell.reuseIdentifier, for: indexPath) as? MatchHistoryTableViewCell else {
            fatalError("""
                Expected `\(MatchHistoryTableViewCell.self)` type for reuseIdentifier "\(MatchHistoryTableViewCell.reuseIdentifier)".
                Ensure that the `\(MatchHistoryTableViewCell.self)` class was registered with the table view (being passed from the view controller).
                """
            )
        }
        
        let match = matches[indexPath.row]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        let dateString = dateFormatter.string(from: match.date)
        
        cell.dateLabel.text = dateString
        
        if match.sets.count >= 1 {
            cell.setOneStackView.isHidden = false
            cell.playerOneSetOneScoreLabel.text = String(match.sets[0].score[0])
            cell.playerTwoSetOneScoreLabel.text = String(match.sets[0].score[1])
            
            if match.sets[0].winner == .playerOne { cell.playerOneSetOneScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[0].winner == .playerTwo { cell.playerTwoSetOneScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
    
        if match.sets.count >= 2 {
            cell.setTwoStackView.isHidden = false
            cell.playerOneSetTwoScoreLabel.text = String(match.sets[1].score[0])
            cell.playerTwoSetTwoScoreLabel.text = String(match.sets[1].score[1])
            
            if match.sets[1].winner == .playerOne { cell.playerOneSetTwoScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[1].winner == .playerTwo { cell.playerTwoSetTwoScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.sets.count >= 3 {
            cell.setThreeStackView.isHidden = false
            cell.playerOneSetThreeScoreLabel.text = String(match.sets[2].score[0])
            cell.playerTwoSetThreeScoreLabel.text = String(match.sets[2].score[1])
            
            if match.sets[2].winner == .playerOne { cell.playerOneSetThreeScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[2].winner == .playerTwo { cell.playerTwoSetThreeScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.sets.count >= 4 {
            cell.setFourStackView.isHidden = false
            cell.playerOneSetFourScoreLabel.text = String(match.sets[3].score[0])
            cell.playerTwoSetFourScoreLabel.text = String(match.sets[3].score[1])
            
            if match.sets[3].winner == .playerOne { cell.playerOneSetFourScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[3].winner == .playerTwo { cell.playerTwoSetFourScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.sets.count >= 5 {
            cell.setFiveStackView.isHidden = false
            cell.playerOneSetFiveScoreLabel.text = String(match.sets[4].score[0])
            cell.playerTwoSetFiveScoreLabel.text = String(match.sets[4].score[1])
            
            if match.sets[4].winner == .playerOne { cell.playerOneSetFiveScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[4].winner == .playerTwo { cell.playerTwoSetFiveScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.winner == .playerOne { cell.playerOneName.font = .preferredFont(forTextStyle: .headline) }
        if match.winner == .playerTwo { cell.playerTwoName.font = .preferredFont(forTextStyle: .headline) }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            matches.remove(at: indexPath.row)
            
            database.delete(withRecordID: records[indexPath.row].recordID) { (recordID, error) in
                if let error = error {
                    print(error)
                } else {
                    self.records.remove(at: indexPath.row)
                }
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("\(#function): activationState:\(WCSession.default.activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("\(#function): activationState = \(session.activationState.rawValue)")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Activate the new session after having switched to a new watch.
        session.activate()
    }
    
    // MARK: - CloudKit
    
    private func fetchMatches() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Match", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { (fetchedRecords, error) in
            if let fetchedRecords = fetchedRecords {
                self.records = fetchedRecords
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
            
            if let error = error {
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Refresh
    
    func configureRefreshControl () {
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        fetchMatches()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}

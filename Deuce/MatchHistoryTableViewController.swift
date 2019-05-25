//
//  MatchHistoryTableViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 5/23/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity

class MatchHistoryTableViewController: UITableViewController, WCSessionDelegate {
    
    var matches = [Match]()
    
    var session: WCSession?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchHistoryTableViewCell", for: indexPath)

        return cell
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
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        if let matchData = userInfo["Match"] as? Data {
            let propertyListDecoder = PropertyListDecoder()
            if let match = try? propertyListDecoder.decode(Match.self, from: matchData) {
                let newIndexPath = IndexPath(row: self.matches.count, section: 0)
                matches.append(match)
                DispatchQueue.main.async {
                    self.tableView.insertRows(at: [newIndexPath], with: .automatic)
                    self.tableView.reloadData()
                }
            }
        }
    }
}

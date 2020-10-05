//
//  MatchHistoryTableViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 5/23/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import UIKit
import os.log
import CloudKit
import SafariServices
import SwiftUI

class MatchHistoryTableViewController: UITableViewController {
    // MARK: - Properties
    
    var matches = [Match]()
    
    let database = CKContainer(identifier: "iCloud.com.example.Deuce.watchkitapp.watchkitextension").privateCloudDatabase
    
    var records = [CKRecord]() {
        didSet {
            if !records.isEmpty {
                matches.removeAll()
                
                for record in records {
                    let matchData = record["matchData"] as! Data
                    let propertyListDecoder = PropertyListDecoder()
                    do {
                        let match = try propertyListDecoder.decode(Match.self, from: matchData)
                        matches.append(match)
                    } catch {
                        print(error)
                    }
                }
                
                if records.count > oldValue.count && matches.count > 1, let previousMatchIndex = matches.index(0, offsetBy: 1, limitedBy: 1) {
                    if let previousPlayerOneName = matches[previousMatchIndex].playerOneName {
                        matches[0].playerOneName = previousPlayerOneName

                        let matchRecord = self.records[0]
                        if let matchData = try? PropertyListEncoder().encode(self.matches[0]) {
                            matchRecord["matchData"] = matchData as NSData

                            self.database.save(matchRecord) { (savedRecord, error) in
                                if let error = error { print(error.localizedDescription) }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.tableView.refreshControl?.endRefreshing()
                }
            } else {
                DispatchQueue.main.async {
                    self.tableView.refreshControl?.endRefreshing()
                }
            }
        }
    }
    
    let propertyListDecoder = PropertyListDecoder()
    
    var becomeActiveObserver: NSObjectProtocol?
    
    let cloudController = CloudController()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        configureRefreshControl()
        addObservers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        
        if let becomeActiveObserver = self.becomeActiveObserver {
            NotificationCenter.default.removeObserver(becomeActiveObserver)
        }
    }
    
    fileprivate func addObservers() {
        becomeActiveObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: OperationQueue.main) { notification in
            self.fetchMatchRecords()
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
        cell.playerTwoNameLabel.text = NSLocalizedString("Opponent", comment: "")
        
        if let playerOneName = match.playerOneName { cell.playerOneNameLabel.text = playerOneName }
        if let playerTwoName = match.playerTwoName { cell.playerTwoNameLabel.text = playerTwoName }
        
        if match.sets.count >= 1 {
            cell.setOneStackView.isHidden = false
            cell.playerOneSetOneScoreLabel.text = String(match.sets[0].gamesWon[0])
            cell.playerTwoSetOneScoreLabel.text = String(match.sets[0].gamesWon[1])
            
            if match.sets[0].winner == .playerOne { cell.playerOneSetOneScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[0].winner == .playerTwo { cell.playerTwoSetOneScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
    
        if match.sets.count >= 2 {
            cell.setTwoStackView.isHidden = false
            cell.playerOneSetTwoScoreLabel.text = String(match.sets[1].gamesWon[0])
            cell.playerTwoSetTwoScoreLabel.text = String(match.sets[1].gamesWon[1])
            
            if match.sets[1].winner == .playerOne { cell.playerOneSetTwoScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[1].winner == .playerTwo { cell.playerTwoSetTwoScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.sets.count >= 3 {
            cell.setThreeStackView.isHidden = false
            cell.playerOneSetThreeScoreLabel.text = String(match.sets[2].gamesWon[0])
            cell.playerTwoSetThreeScoreLabel.text = String(match.sets[2].gamesWon[1])
            
            if match.sets[2].winner == .playerOne { cell.playerOneSetThreeScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[2].winner == .playerTwo { cell.playerTwoSetThreeScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.sets.count >= 4 {
            cell.setFourStackView.isHidden = false
            cell.playerOneSetFourScoreLabel.text = String(match.sets[3].gamesWon[0])
            cell.playerTwoSetFourScoreLabel.text = String(match.sets[3].gamesWon[1])
            
            if match.sets[3].winner == .playerOne { cell.playerOneSetFourScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[3].winner == .playerTwo { cell.playerTwoSetFourScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.sets.count >= 5 {
            cell.setFiveStackView.isHidden = false
            cell.playerOneSetFiveScoreLabel.text = String(match.sets[4].gamesWon[0])
            cell.playerTwoSetFiveScoreLabel.text = String(match.sets[4].gamesWon[1])
            
            if match.sets[4].winner == .playerOne { cell.playerOneSetFiveScoreLabel.font = .preferredFont(forTextStyle: .headline) }
            if match.sets[4].winner == .playerTwo { cell.playerTwoSetFiveScoreLabel.font = .preferredFont(forTextStyle: .headline) }
        }
        
        if match.winner == .playerOne { cell.playerOneNameLabel.font = .preferredFont(forTextStyle: .headline) }
        if match.winner == .playerTwo { cell.playerTwoNameLabel.font = .preferredFont(forTextStyle: .headline) }

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
                    print(error.localizedDescription)
                } else {
                    self.records.remove(at: indexPath.row)
                }
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editNames(indexPath, tableView)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let matchDetail = MatchDetail(match: self.matches[indexPath.row]) { [weak self] newMatch in
            self?.dismiss(animated: true) {
                self?.matches[indexPath.row] = newMatch
                
                let matchRecord = self?.records[indexPath.row]
                
                if let matchData = try? PropertyListEncoder().encode(self?.matches[indexPath.row]) {
                    matchRecord?["matchData"] = matchData as NSData
                    
                    self?.database.save(matchRecord!) { (savedRecord, error) in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        let hostingController = UIHostingController(rootView: matchDetail)
        self.present(hostingController, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
        
        
    }
    
    // MARK: - CloudKit
    
    private func fetchMatchRecords() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Match", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        database.perform(query, inZoneWith: nil) { (fetchedRecords, error) in
            if let fetchedRecords = fetchedRecords {
                self.records = fetchedRecords
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
        fetchMatchRecords()
    }
    
    // MARK: - Editing
    
    fileprivate func editNames(_ indexPath: IndexPath, _ tableView: UITableView) {
        let alert = UIAlertController(title: "Player Names", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "\(NSLocalizedString("Opponent", tableName: "Main", comment: "")) (e.g. Benoit Paire)"
            textField.autocapitalizationType = .words
            textField.returnKeyType = .next
            textField.clearButtonMode = .whileEditing
            
            if let playerTwoName = self.matches[indexPath.row].playerTwoName {
                textField.text = playerTwoName
            }
        }
        
        alert.addTextField { textField in
            textField.placeholder = "\(NSLocalizedString("You", tableName: "Main", comment: "")) (e.g. Gael Monfils)"
            textField.autocapitalizationType = .words
            textField.returnKeyType = .done
            textField.clearButtonMode = .whileEditing
            textField.textContentType = .name
            
            if let playerOneName = self.matches[indexPath.row].playerOneName {
                textField.text = playerOneName
            }
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Main", comment: ""), style: .cancel, handler: { _ in
            tableView.deselectRow(at: indexPath, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Save", tableName: "Main", comment: "Default action"), style: .default, handler: { _ in
            if let playerOneName = alert.textFields?.last?.text, !playerOneName.isEmpty {
                self.matches[indexPath.row].playerOneName = playerOneName
            }
            
            if let playerTwoName = alert.textFields?.first?.text, !playerTwoName.isEmpty {
                self.matches[indexPath.row].playerTwoName = playerTwoName
            }
            
            let matchRecord = self.records[indexPath.row]
            
            if let matchData = try? PropertyListEncoder().encode(self.matches[indexPath.row]) {
                matchRecord["matchData"] = matchData as NSData
                
                self.database.save(matchRecord) { (savedRecord, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        DispatchQueue.main.async {
                            self.fetchMatchRecords()
                        }
                    }
                }
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func presentRules(_ sender: UIBarButtonItem) {
        var url: URL
        switch Locale.current.languageCode {
        case "fr":
            url = URL(string: "https://www.fft.fr/file/7966/download?token=DmjkAHAr")!
        default:
            url = URL(string: "https://www.itftennis.com/media/2510/2020-rules-of-tennis-english.pdf")!
        }
        let rulesViewController = SFSafariViewController(url: url)
        rulesViewController.modalPresentationStyle = .pageSheet
        self.present(rulesViewController, animated: true)
    }
}

extension UserDefaults {
    static let playerOneName = "playerOneName"
}

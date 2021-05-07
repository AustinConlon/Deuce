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

enum Section {
    case main
}

class MatchHistoryTableViewController: UITableViewController {
    class DataSource: UITableViewDiffableDataSource<Section, Match> {
        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return true
        }
        
        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                MatchHistoryController.shared.database.delete(withRecordID: MatchHistoryController.shared.records[indexPath.row].recordID) { (recordID, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        MatchHistoryController.shared.records.remove(at: indexPath.row)
                    }
                }
                
                if let identifierToDelete = itemIdentifier(for: indexPath) {
                    var snapshot = self.snapshot()
                    snapshot.deleteItems([identifierToDelete])
                    apply(snapshot)
                }
            }
        }
    }
    
    let propertyListDecoder = PropertyListDecoder()
    
    var becomeActiveObserver: NSObjectProtocol?
    
    let cloudController = CloudController()
    
    var dataSource: DataSource!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if traitCollection.userInterfaceIdiom != .mac {
            configureRefreshControl()
        }
        addObservers()
    }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureDataSource()
        
        MatchHistoryController.shared.fetchMatchRecords() { matches in
            DispatchQueue.main.async {
                self.dataSource.apply(self.initialSnapshot(), animatingDifferences: false)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let navigationController = navigationController,
           navigationController.isToolbarHidden {
            navigationController.setToolbarHidden(false, animated: animated)
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
            MatchHistoryController.shared.fetchMatchRecords() { matches in
                DispatchQueue.main.async {
                    self.dataSource.apply(self.initialSnapshot(), animatingDifferences: false)
                }
            }
        }
    }
    
    func initialSnapshot() -> NSDiffableDataSourceSnapshot<Section, Match> {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Match>()
        snapshot.appendSections([.main])
        snapshot.appendItems(MatchHistoryController.shared.matches)
        return snapshot
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        editNames(indexPath, tableView)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let matchDetail = MatchDetail(match: MatchHistoryController.shared.matches[indexPath.row]) { [weak self] newMatch in
            self?.dismiss(animated: true) {
                // Save notes edits to CloudKit.
                MatchHistoryController.shared.matches[indexPath.row] = newMatch
                
                let matchRecord = MatchHistoryController.shared.records[indexPath.row]
                
                if let matchData = try? PropertyListEncoder().encode(MatchHistoryController.shared.matches[indexPath.row]) {
                    matchRecord["matchData"] = matchData as NSData
                    
                    MatchHistoryController.shared.database.save(matchRecord) { (savedRecord, error) in
                        if let error = error {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        
        let hostingController = UIHostingController(rootView: matchDetail)
        self.navigationController!.show(hostingController, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Refresh
    
    func configureRefreshControl () {
        refreshControl?.isEnabled = true
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
    }
    
    @objc func handleRefreshControl() {
        MatchHistoryController.shared.fetchMatchRecords() { matches in
            DispatchQueue.main.async {
                self.dataSource.apply(self.initialSnapshot(), animatingDifferences: false)
                self.tableView.refreshControl?.endRefreshing()
            }
        }
    }
    
    // MARK: - Editing
    
    fileprivate func editNames(_ indexPath: IndexPath, _ tableView: UITableView) {
        let alert = UIAlertController(title: "Player Names", message: nil, preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "\(NSLocalizedString("Opponent", tableName: "Main", comment: "")) (e.g. Benoit Paire)"
            textField.autocapitalizationType = .words
            textField.returnKeyType = .next
            textField.clearButtonMode = .whileEditing
            
            if let playerTwoName = MatchHistoryController.shared.matches[indexPath.row].playerTwoName {
                textField.text = playerTwoName
            }
        }
        
        alert.addTextField { textField in
            textField.placeholder = "\(NSLocalizedString("You", tableName: "Main", comment: "")) (e.g. Gael Monfils)"
            textField.autocapitalizationType = .words
            textField.returnKeyType = .done
            textField.clearButtonMode = .whileEditing
            textField.textContentType = .name
            
            if let playerOneName = MatchHistoryController.shared.matches[indexPath.row].playerOneName {
                textField.text = playerOneName
            }
        }
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", tableName: "Main", comment: ""), style: .cancel, handler: { _ in
            tableView.deselectRow(at: indexPath, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Save", tableName: "Main", comment: "Default action"), style: .default, handler: { _ in
            if let playerOneName = alert.textFields?.last?.text, !playerOneName.isEmpty {
                MatchHistoryController.shared.matches[indexPath.row].playerOneName = playerOneName
            }
            
            if let playerTwoName = alert.textFields?.first?.text, !playerTwoName.isEmpty {
                MatchHistoryController.shared.matches[indexPath.row].playerTwoName = playerTwoName
            }
            
            let matchRecord = MatchHistoryController.shared.records[indexPath.row]
            
            if let matchData = try? PropertyListEncoder().encode(MatchHistoryController.shared.matches[indexPath.row]) {
                matchRecord["matchData"] = matchData as NSData
                
                MatchHistoryController.shared.database.save(matchRecord) { (savedRecord, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    } else {
                        MatchHistoryController.shared.fetchMatchRecords() { matches in
                            DispatchQueue.main.async {
                                self.dataSource.apply(self.initialSnapshot(), animatingDifferences: false)
                            }
                        }
                    }
                }
            }
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func rulesButtonTriggered(_ sender: UIBarButtonItem) {
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
    
    @IBAction func addButtonTriggered(_ sender: UIBarButtonItem) {
    }
}

extension UserDefaults {
    static let playerOneName = "playerOneName"
}

extension MatchHistoryTableViewController {
    func configureDataSource() {
        dataSource = DataSource(tableView: self.tableView) { (tableView, indexPath, match) -> MatchHistoryTableViewCell? in
            guard let cell = tableView.dequeueReusableCell(withIdentifier: MatchHistoryTableViewCell.reuseIdentifier, for: indexPath) as? MatchHistoryTableViewCell else {
                fatalError("""
                    Expected `\(MatchHistoryTableViewCell.self)` type for reuseIdentifier "\(MatchHistoryTableViewCell.reuseIdentifier)".
                    Ensure that the `\(MatchHistoryTableViewCell.self)` class was registered with the table view (being passed from the view controller).
                    """
                )
            }
            
            let match = MatchHistoryController.shared.matches[indexPath.row]
            
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
    }
}

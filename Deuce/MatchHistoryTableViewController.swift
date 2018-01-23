//
//  MatchHistoryTableViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 1/8/18.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import UIKit
import WatchConnectivity

class MatchHistoryTableViewController: UITableViewController, WCSessionDelegate  {
        
    var matchs = [Match]() {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var session: WCSession!
    var isConnected: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeView()
        print("in did load")
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Helper Methods -----------
    
    func initializeView() {
        if (WCSession.isSupported()) {
            let session = WCSession.default()
            session.delegate = self
            session.activate() // activate the session
        }
    }
    
    func createNewMatchCell(maxSets: Int) {
        let match = Match(player: "Bijans", opponent: "Aussie", date: "04/21/1994",maxSets: maxSets,isLive: true)
        matchs.insert(match, at: 0)
    }
    
    //MARK: SessionDelegate delegate
    
    func session(_ session: WCSession, activationDidCompleteWith : WCSessionActivationState, error: Error?) {
        
        if !session.isPaired { // Check if the iPhone is paired with the Apple Watch
            let alert = UIAlertController(title: "pls", message: "Connect Your Watch.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Default action"), style: .`default`, handler: { _ in
                NSLog("The \"OK\" alert occured.")
            }))
            isConnected = false
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.sync {
            if let val = message["live"] {
                createNewMatchCell(maxSets: val as! Int)
            } else if let val = message["score"] {
                updateScore(msg: val as! String)
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Inactivated")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("deactivated")
    }
    
    //class methods
    func updateScore(msg: String) {
        
        let currMatch = self.matchs.filter( {(value: Match) -> Bool in
            return value.isLive
        })[0]
        let last = currMatch.playerScores.count - 1
        
        if currMatch.inDeuce {
            if msg == "player" && currMatch.opponentScores[last] == 4 {
                currMatch.opponentScores[last] -= 1
            } else if msg == "player" && currMatch.playerScores[last] == currMatch.opponentScores[last] {
                currMatch.playerScores[last] += 1
            } else if msg == "opponent" && currMatch.playerScores[last] == 4 {
                currMatch.playerScores[last] -= 1
            } else if msg == "opponent" && currMatch.playerScores[last] == currMatch.opponentScores[last] {
                currMatch.opponentScores[last] += 1
            } else {
                print("nextGame Triggered")
                currMatch.inDeuce = false
                currMatch.nextGame()
            }
        } else {
            if msg == "player" {
                currMatch.playerScores[last] += 1
            } else {
                currMatch.opponentScores[last] += 1
            }
        }
        
        
        if currMatch.playerScores[last] == 3 && currMatch.opponentScores[last] == 3 {
            currMatch.inDeuce = true
        }
        self.tableView.reloadData()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return matchs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "match"
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? MatchHistoryTableViewCell  else {
            fatalError("The dequeued cell is not an instance of MatchTableViewCell.")
        }
        let match = matchs[indexPath.row]
        
        cell.playerName.text = match.player
        cell.opponentName.text = match.opponent
        
        cell.playerSetScores.clearStack()
        cell.playerSetScores.populateStack(playerScores: match.playerScores)
        
        cell.opponentSetScores.clearStack()
        cell.opponentSetScores.populateStack(playerScores: match.opponentScores)
        
        if match.isLive {
            cell.dateLabel.text = "LIVE"
            cell.dateLabel.textColor = UIColor.red
        } else {
            cell.dateLabel.text = match.date
        }
            
        return cell
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

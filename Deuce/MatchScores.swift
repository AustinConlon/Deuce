//
//  MatchScores.swift
//  Deuce
//
//  Created by Bijan Massoumi on 1/18/18.
//  Copyright © 2018 Bijan Massoumi. All rights reserved.
//

import UIKit

class MatchScores: UIStackView {
    
    private let scoreKey = [0: " 0", 1: " 15", 2: " 30", 3: " 40", 4: " 40"]

    private var setScores = [UILabel]()
    private var currSet = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func addToStack(newScore: String) {
        let newLabel = UILabel()
        
        newLabel.text = newScore
        newLabel.backgroundColor = UIColor.black
        newLabel.textColor = UIColor.green
        
        // Add constraints
        newLabel.translatesAutoresizingMaskIntoConstraints = false
        newLabel.heightAnchor.constraint(equalToConstant: 21.0).isActive = true
        //newLabel.widthAnchor.constraint(equalToConstant: 21.0).isActive = true
        
        addArrangedSubview(newLabel)
        setScores.append(newLabel)
    }
    
    //MARK: public methods
    func populateStack( playerScores: [Int], maxSets: Int, isLive: Bool) {
        if maxSets == 1 {
            if (!isLive) {
               addToStack(newScore: String(playerScores[0]))
            } else {
                addToStack(newScore: scoreKey[playerScores[0]]!)
            }
        } else {
            if (!isLive) {
                playerScores.map( { (score: Int) in
                    addToStack(newScore: String(score))
                })
            } else {
                for (i, score) in playerScores.enumerated() {
                    if (i == playerScores.count - 1) {
                        addToStack(newScore: scoreKey[score]!)
                    } else {
                        addToStack(newScore: String(score))
                    }
                }
                
            }
        }
    }
    
    func clearStack() {
        setScores.map({ (label: UILabel) in
            self.removeArrangedSubview(label)
        })
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

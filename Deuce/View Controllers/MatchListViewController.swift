//
//  MatchListViewController.swift
//  Deuce
//
//  Created by Austin Conlon on 5/23/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import UIKit

private enum Section: Hashable {
    case main
}

class MatchListViewController: UITableViewController {
    private var dataSource: UICollectionViewDiffableDataSource<Section, Match>! = nil
    private var collectionView: UICollectionView! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Match History"
        configureHierarchy()
//        configureDataSource()
    }
}

extension MatchListViewController {
    private func createLayout() -> UICollectionViewLayout {
        let configuration = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: configuration)
    }
}

extension MatchListViewController {
    private func configureHierarchy() {
        
    }
}

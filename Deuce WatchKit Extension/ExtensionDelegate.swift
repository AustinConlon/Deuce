//
//  ExtensionDelegate.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 11/27/16.
//  Copyright © 2018 Austin Conlon. All rights reserved.
//

import WatchKit
import HealthKit

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        requestAccessToHealthKit()
    }
    
    private func requestAccessToHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthStore = HKHealthStore()
        
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            if let error = error, !success {
                print(error.localizedDescription)
            }
        }
    }
}

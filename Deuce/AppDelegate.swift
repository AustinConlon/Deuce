//
//  AppDelegate.swift
//  Deuce
//
//  Created by Austin Conlon on 11/27/16.
//  Copyright © 2016 Austin Conlon. All rights reserved.
//

import UIKit
import HealthKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        self.requestAccessToHealthKit()
        return true
    }
    
    private func requestAccessToHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let healthStore = HKHealthStore()
        
        let allTypes = Set([HKObjectType.workoutType(),
                            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!])
        
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { (success, error) in
            if let error = error, !success {
                print(error.localizedDescription)
            }
        }
    }
}


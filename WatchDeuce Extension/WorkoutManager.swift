//
//  WorkoutManager.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 2/10/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation
import HealthKit

class WorkoutManager: NSObject, HKWorkoutSessionDelegate, ObservableObject {
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    var start: Date?
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    
    // MARK: - Methods
    func requestAuthorization() {
        let typesToShare: Swift.Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKWorkoutType.workoutType()
        ]
        
        let typesToRead: Swift.Set = [
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        if healthStore.authorizationStatus(for: .workoutType()) == .notDetermined {
            healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
                
            }
        }
    }
    
    func startWorkout() {
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .tennis
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore,
                                                  configuration: workoutConfiguration)
            builder = session!.associatedWorkoutBuilder()
            start = Date()
        } catch {
            return
        }
        
        session?.startActivity(with: start)
        
        builder!.beginCollection(withStart: start!) { (success, error) in
            
        }
        
        let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                 workoutConfiguration: workoutConfiguration)
        
        builder?.dataSource = dataSource
        
        session?.delegate = self
    }
    
    func stop() {
        let totalEnergyBurnedSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                                       quantity: self.totalEnergyBurned,
                                                       start: self.start!,
                                                       end: Date())
        builder?.add([totalEnergyBurnedSample]) { (success, error) in
            
        }
        
        session?.end()
        
        builder?.endCollection(withEnd: Date()) { (success, error) in
            
        }
        
        builder?.finishWorkout { (workout, error) in
            
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session changed from \(fromState.rawValue) to \(toState.rawValue).")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

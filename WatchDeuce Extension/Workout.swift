//
//  Workout.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 2/10/19.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import Foundation
import HealthKit

class Workout: NSObject, HKWorkoutSessionDelegate {
    // MARK: - Properties
    var workoutSession: HKWorkoutSession?
    let healthStore = HKHealthStore()
    var liveWorkoutBuilder: HKLiveWorkoutBuilder?
    var workoutStartDate: Date?
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    
    // MARK: - Methods
    func requestAuthorization() {
        let typesToShare: Swift.Set = [
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
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
    
    func start() {
        if healthStore.authorizationStatus(for: .workoutType()) == .sharingAuthorized {
            let workoutConfiguration = HKWorkoutConfiguration()
            workoutConfiguration.activityType = .tennis
            
            do {
                workoutSession = try HKWorkoutSession(healthStore: healthStore,
                                                      configuration: workoutConfiguration)
                liveWorkoutBuilder = workoutSession!.associatedWorkoutBuilder()
                workoutStartDate = Date()
            } catch {
                return
            }
            
            workoutSession?.startActivity(with: workoutStartDate)
            
            liveWorkoutBuilder!.beginCollection(withStart: workoutStartDate!) { (success, error) in
                
            }
            
            let dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: workoutConfiguration)
            
            liveWorkoutBuilder?.dataSource = dataSource
            
            workoutSession?.delegate = self
        }
    }
    
    func stop() {
        let totalEnergyBurnedSample = HKQuantitySample(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
                                                       quantity: self.totalEnergyBurned,
                                                       start: self.workoutStartDate!,
                                                       end: Date())
        liveWorkoutBuilder?.add([totalEnergyBurnedSample]) { (success, error) in
            
        }
        
        workoutSession?.end()
        
        liveWorkoutBuilder?.endCollection(withEnd: Date()) { (success, error) in
            
        }
        
        liveWorkoutBuilder?.finishWorkout { (workout, error) in
            
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session changed from \(fromState.rawValue) to \(toState.rawValue).")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

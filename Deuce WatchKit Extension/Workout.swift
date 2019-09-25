//
//  Workout.swift
//  Deuce WatchKit Extension
//
//  Created by Austin Conlon on 2/10/19.
//  Copyright © 2019 Austin Conlon. All rights reserved.
//

import Foundation
import HealthKit

class Workout: NSObject, HKWorkoutSessionDelegate {
    // Properties
    var workoutSession: HKWorkoutSession?
    var healthStore = HKHealthStore()
    var liveWorkoutBuilder: HKLiveWorkoutBuilder?
    var workoutStartDate: Date?
    var totalEnergyBurned = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: 0)
    
    func requestAuthorization() {
        // Create the heart rate and heartbeat type identifiers.
        let sampleTypesToShare = Set([HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!, HKWorkoutType.workoutType()])
        let sampleTypesToRead = Set([HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, HKObjectType.quantityType(forIdentifier: .heartRate)!])
        
        // Request permission to read and write heart rate and heartbeat data.
        healthStore.requestAuthorization(toShare: sampleTypesToShare, read: sampleTypesToRead) { (success, error) in
            print("Request Authorization -- Success: ", success, " Error: ", error ?? "nil")
            // Handle authorization errors here.
        }
    }
    
    func start() {
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
        
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

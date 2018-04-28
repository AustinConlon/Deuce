//
//  WorkoutManager.swift
//
//  Copyright (C) 2016 Apple Inc. All Rights Reserved.
//

import Foundation
import HealthKit

class WorkoutManager {
    // MARK: Properties
    let healthStore = HKHealthStore()
    
    var session: HKWorkoutSession?
    
    // MARK: WorkoutManager
    
    func startWorkout() {
        // If we have already started the workout, then do nothing.
        if (session != nil) {
            return
        }
        
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .tennis
        workoutConfiguration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
        } catch {
            fatalError("Unable to create the workout session!")
        }
        
        // Start the workout session and device motion updates.
        healthStore.start(session!)
    }
    
    func stopWorkout() {
        // If we have already stopped the workout, then do nothing.
        if (session == nil) {
            return
        }
        
        // Stop the device motion updates and workout session.
        healthStore.end(session!)
        
        // Clear the workout session.
        session = nil
    }
}

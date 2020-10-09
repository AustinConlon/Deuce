//
//  WorkoutView.swift
//  WatchDeuce Extension
//
//  Created by Austin Conlon on 10/6/20.
//  Copyright © 2020 Austin Conlon. All rights reserved.
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(elapsedTimeString(elapsed: secondsToHoursMinutesSeconds(seconds: workoutManager.elapsedSeconds)))").frame(alignment: .leading)
                .font(Font.system(.largeTitle).monospacedDigit().weight(.medium))
            
            Text("\(workoutManager.activeCalories, specifier: "%.1f") cal")
                .font(Font.system(.largeTitle).monospacedDigit().weight(.medium))
            .frame(alignment: .leading)
            
            Text("\(workoutManager.heartrate, specifier: "%.1f") BPM")
            .font(Font.system(size: 26, weight: .regular, design: .default).monospacedDigit())
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
    }
    
    // Convert the seconds into seconds, minutes, hours.
    func secondsToHoursMinutesSeconds (seconds: Int) -> (Int, Int, Int) {
      return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    
    // Convert the seconds, minutes, hours into a string.
    func elapsedTimeString(elapsed: (h: Int, m: Int, s: Int)) -> String {
        return String(format: "%d:%02d.%02d", elapsed.h, elapsed.m, elapsed.s)
    }
}

struct WorkoutView_Previews: PreviewProvider {
    static var previews: some View {
        return Group {
            Group {
                Group {
                    WorkoutView()
                        .environment(\.sizeCategory, .extraSmall)
                    WorkoutView()
                        .environment(\.sizeCategory, .small)
                    WorkoutView()
                        .environment(\.sizeCategory, .medium)
                    WorkoutView()
                        .environment(\.sizeCategory, .large)
                    WorkoutView()
                        .environment(\.sizeCategory, .extraLarge)
                    WorkoutView()
                        .environment(\.sizeCategory, .extraExtraLarge)
                    WorkoutView()
                        .environment(\.sizeCategory, .extraExtraExtraLarge)
                }
                
                Group {
                    WorkoutView()
                        .environment(\.sizeCategory, .accessibilityMedium)
                    WorkoutView()
                        .environment(\.sizeCategory, .accessibilityLarge)
                    WorkoutView()
                        .environment(\.sizeCategory, .accessibilityExtraLarge)
                    WorkoutView()
                        .environment(\.sizeCategory, .accessibilityExtraExtraLarge)
                }
            }
            .environment(\.locale, .init(identifier: "en"))
        }
        .environmentObject(WorkoutManager())
    }
}

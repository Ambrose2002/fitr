//
//  WorkoutSessionClassifier.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/1/26.
//

import Foundation

enum WorkoutSessionClassifier {
  static func workoutType(for workout: WorkoutSessionResponse) -> WorkoutHistoryType {
    guard !workout.workoutExercises.isEmpty else {
      return .strength
    }

    let uniqueModalities = Set(
      workout.workoutExercises.map { workoutExercise in
        WorkoutHistoryType.modality(for: workoutExercise.exercise.measurementType)
      }
    )

    if uniqueModalities.count == 1, let onlyType = uniqueModalities.first {
      return onlyType
    }

    return .hybrid
  }
}

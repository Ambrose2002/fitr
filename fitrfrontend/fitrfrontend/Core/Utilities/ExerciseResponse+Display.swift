//
//  ExerciseResponse+Display.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 4/11/26.
//

import Foundation

extension ExerciseResponse {
  var isCustomExercise: Bool {
    isSystemDefined == false
  }

  var sourceBadgeText: String {
    isCustomExercise ? "MY EXERCISE" : "SYSTEM"
  }
}

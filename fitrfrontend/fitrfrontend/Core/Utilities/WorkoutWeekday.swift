//
//  WorkoutWeekday.swift
//  fitrfrontend
//
//  Created by Codex on 2/28/26.
//

import Foundation

enum WorkoutWeekday: Int, CaseIterable, Identifiable {
  case sunday = 1
  case monday = 2
  case tuesday = 3
  case wednesday = 4
  case thursday = 5
  case friday = 6
  case saturday = 7

  var id: Int {
    rawValue
  }

  var fullName: String {
    switch self {
    case .sunday:
      return "Sunday"
    case .monday:
      return "Monday"
    case .tuesday:
      return "Tuesday"
    case .wednesday:
      return "Wednesday"
    case .thursday:
      return "Thursday"
    case .friday:
      return "Friday"
    case .saturday:
      return "Saturday"
    }
  }

  var shortName: String {
    switch self {
    case .sunday:
      return "Sun"
    case .monday:
      return "Mon"
    case .tuesday:
      return "Tue"
    case .wednesday:
      return "Wed"
    case .thursday:
      return "Thu"
    case .friday:
      return "Fri"
    case .saturday:
      return "Sat"
    }
  }

  var badgeName: String {
    shortName.uppercased()
  }

  static func from(dayNumber: Int) -> WorkoutWeekday? {
    WorkoutWeekday(rawValue: dayNumber)
  }
}

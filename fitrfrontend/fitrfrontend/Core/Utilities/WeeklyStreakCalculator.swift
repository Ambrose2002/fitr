//
//  WeeklyStreakCalculator.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/5/26.
//

import Foundation

enum WeeklyStreakCalculator {
  static func calculate(
    workoutDates: [Date],
    now: Date = Date(),
    calendar: Calendar = .current
  ) -> Int {
    guard !workoutDates.isEmpty else {
      return 0
    }

    var weekCalendar = calendar
    weekCalendar.firstWeekday = 1  // Sunday

    let qualifiedWeeks = Set(
      workoutDates.map { startOfWeek(for: $0, calendar: weekCalendar) }
    )

    let currentWeekStart = startOfWeek(for: now, calendar: weekCalendar)
    let previousWeekStart =
      weekCalendar.date(byAdding: .day, value: -7, to: currentWeekStart) ?? currentWeekStart

    let anchorWeek: Date
    if qualifiedWeeks.contains(currentWeekStart) {
      anchorWeek = currentWeekStart
    } else if qualifiedWeeks.contains(previousWeekStart) {
      anchorWeek = previousWeekStart
    } else {
      return 0
    }

    var streak = 0
    var weekCursor = anchorWeek

    while qualifiedWeeks.contains(weekCursor) {
      streak += 1
      guard let previousWeek = weekCalendar.date(byAdding: .day, value: -7, to: weekCursor) else {
        break
      }
      weekCursor = previousWeek
    }

    return streak
  }

  private static func startOfWeek(for date: Date, calendar: Calendar) -> Date {
    let startOfDay = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: startOfDay)
    let offset = (weekday - calendar.firstWeekday + 7) % 7
    return calendar.date(byAdding: .day, value: -offset, to: startOfDay) ?? startOfDay
  }
}

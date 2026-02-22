//
//  Constants.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct Constants {
    static let baseUrl : String = "http://127.0.0.1:8080"
}
// MARK: - Date Formatting
struct DateFormatter {
  static func relativeDate(from date: Date, to referenceDate: Date = .now) -> String {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day, .weekOfYear, .month, .year], from: date, to: referenceDate)
    
    if let day = components.day {
      switch day {
      case 0:
        return "Today"
      case 1:
        return "Yesterday"
      case 2...6:
        return "\(day) days ago"
      case 7...13:
        return "1 week ago"
      case 14...27:
        let weeks = day / 7
        return "\(weeks) weeks ago"
      case 28...:
        if let weeks = components.weekOfYear, weeks > 0 {
          return "\(weeks) weeks ago"
        } else if let months = components.month {
          return "\(months) month\(months > 1 ? "s" : "") ago"
        }
        // Fallback to date format for older dates
        let formatter = Foundation.DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
      default:
        return ""
      }
    }
    
    return ""
  }
}

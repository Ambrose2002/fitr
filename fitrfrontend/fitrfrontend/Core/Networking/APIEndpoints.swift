//
//  APIEndpoints.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

struct APIEndpoints {
    // Authentication
    static let login = "/auth/login"
    static let signup = "/auth/signup"
    
    // User
    static let currentUser = "/api/me"
    static let userProfile = "/api/me/profile"
    
    // Exercises
    static let exercises = "/api/exercise"
    static func exercise(id: Int) -> String { "/api/exercise/\(id)" }
    
    // Workout Plans
    static let plans = "/api/plans"
    static func plan(id: Int) -> String { "/api/plans/\(id)" }
    static func planDays(planId: Int) -> String { "/api/plans/\(planId)/days" }
    
    // Workout Sessions
    static let workouts = "/api/workouts"
    static func workout(id: Int) -> String { "/api/workouts/\(id)" }
    
    // Body Metrics
    static let bodyMetrics = "/api/body-metrics"
    
    // Locations
    static let locations = "/api/locations"
}

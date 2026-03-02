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
    static let activeWorkout = "/api/workouts/active"
    static func workout(id: Int) -> String { "/api/workouts/\(id)" }
    static func workoutExercises(workoutId: Int) -> String { "/api/workouts/\(workoutId)/exercises" }
    static func workoutExerciseSets(workoutExerciseId: Int) -> String {
        "/api/workout-exercises/\(workoutExerciseId)/sets"
    }
    static func workoutExerciseSet(workoutExerciseId: Int, setId: Int) -> String {
        "/api/workout-exercises/\(workoutExerciseId)/sets/\(setId)"
    }
    static func workoutExerciseSetLogs(workoutExerciseId: Int) -> String {
        "/api/workout-exercises/\(workoutExerciseId)/set-logs"
    }
    static func workoutExerciseSetLog(workoutExerciseId: Int, setId: Int) -> String {
        "/api/workout-exercises/\(workoutExerciseId)/set-logs/\(setId)"
    }
    
    // Body Metrics
    static let bodyMetrics = "/api/body-metrics"
    
    // Locations
    static let locations = "/api/locations"
}

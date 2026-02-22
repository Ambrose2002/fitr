//
//  MockData.swift
//  fitrfrontend
//
//  Created on 2/21/26.
//

import Foundation

/// Centralized mock data for previews and testing across the app
struct MockData {
  // MARK: - Authentication & User Profile

  static let testToken =
    "eyJhbGciOiJIUzUxMiJ9.eyJzdWIiOiJhYkBnbWFpbC5jb20iLCJpYXQiOjE3NzE3MTc5OTgsImV4cCI6MTc3MTgwNDM5OH0.8tIxswwMRif4gmudPPYdtoW1P8tSJRldtFURC-KUU2IdU4xNvghNRTzloDcN-73x-v2rd8qPN11Pdq0_XVb28g"

  static let mockProfile = UserProfileResponse(
    id: 1,
    userId: 1,
    firstname: "Alex",
    lastname: "Taylor",
    email: "alex@example.com",
    gender: .male,
    height: 180,
    weight: 82.4,
    experience: .intermediate,
    goal: .strength,
    preferredWeightUnit: .kg,
    preferredDistanceUnit: .km,
    createdAt: Date()
  )

  static func mockSessionStore(userProfile: UserProfileResponse = mockProfile) -> SessionStore {
    let store = SessionStore.mock(userProfile: userProfile)
    store.accessToken = testToken
    return store
  }

  // MARK: - Home Screen Data

  /// Scenario 1: Zero workouts (new user)
  static let zeroWorkoutsData = HomeScreenData(
    greeting: "Hey Alex!",
    weekProgress: "You've hit 0 workouts this week. 5 to go!",
    nextSession: nil,
    lastWorkout: nil,
    currentWeight: "82.4",
    weightChange: "0.0",
    streak: 0,
    streakPercentile: 0,
    weeklyWorkoutCount: 0,
    weeklyTotalVolume: "0",
    weeklyCaloriesBurned: "0 cal",
    weeklyAvgDuration: "0 min",
    weeklyPersonalRecords: [],
    weeklyExerciseVariety: 0
  )

  /// Scenario 2: One workout (partial history)
  static let oneWorkoutData = HomeScreenData(
    greeting: "Great work!",
    weekProgress: "You've hit 1 workouts this week. 4 to go!",
    nextSession: WorkoutSessionResponse(
      id: 1,
      userId: 1,
      startTime: Date().addingTimeInterval(3600),
      title: "Chest and Triceps",
      workoutExercises: [
        WorkoutExerciseResponse(
          id: 1,
          workoutSessionId: 1,
          exercise: ExerciseResponse(
            id: 1, name: "Bench Press", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 1, workoutExerciseId: 1, setNumber: 1, completedAt: Date(), weight: 185, reps: 8,
              durationSeconds: 45, distance: 0, calories: 12),
            SetLogResponse(
              id: 2, workoutExerciseId: 1, setNumber: 2, completedAt: Date(), weight: 195, reps: 6,
              durationSeconds: 48, distance: 0, calories: 13),
            SetLogResponse(
              id: 3, workoutExerciseId: 1, setNumber: 3, completedAt: Date(), weight: 205, reps: 4,
              durationSeconds: 52, distance: 0, calories: 14),
            SetLogResponse(
              id: 4, workoutExerciseId: 1, setNumber: 4, completedAt: Date(), weight: 195, reps: 6,
              durationSeconds: 50, distance: 0, calories: 13),
          ]
        ),
        WorkoutExerciseResponse(
          id: 2,
          workoutSessionId: 1,
          exercise: ExerciseResponse(
            id: 2, name: "Incline Dumbbell Press", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 5, workoutExerciseId: 2, setNumber: 1, completedAt: Date(), weight: 70, reps: 10,
              durationSeconds: 42, distance: 0, calories: 11),
            SetLogResponse(
              id: 6, workoutExerciseId: 2, setNumber: 2, completedAt: Date(), weight: 75, reps: 8,
              durationSeconds: 44, distance: 0, calories: 12),
            SetLogResponse(
              id: 7, workoutExerciseId: 2, setNumber: 3, completedAt: Date(), weight: 80, reps: 6,
              durationSeconds: 46, distance: 0, calories: 12),
          ]
        ),
        WorkoutExerciseResponse(
          id: 3,
          workoutSessionId: 1,
          exercise: ExerciseResponse(
            id: 3, name: "Cable Fly", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 8, workoutExerciseId: 3, setNumber: 1, completedAt: Date(), weight: 40, reps: 12,
              durationSeconds: 38, distance: 0, calories: 10),
            SetLogResponse(
              id: 9, workoutExerciseId: 3, setNumber: 2, completedAt: Date(), weight: 45, reps: 10,
              durationSeconds: 40, distance: 0, calories: 11),
            SetLogResponse(
              id: 10, workoutExerciseId: 3, setNumber: 3, completedAt: Date(), weight: 50, reps: 8,
              durationSeconds: 42, distance: 0, calories: 11),
          ]
        ),
        WorkoutExerciseResponse(
          id: 4,
          workoutSessionId: 1,
          exercise: ExerciseResponse(
            id: 4, name: "Tricep Pushdown", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 11, workoutExerciseId: 4, setNumber: 1, completedAt: Date(), weight: 60, reps: 12,
              durationSeconds: 35, distance: 0, calories: 9),
            SetLogResponse(
              id: 12, workoutExerciseId: 4, setNumber: 2, completedAt: Date(), weight: 65, reps: 10,
              durationSeconds: 37, distance: 0, calories: 10),
            SetLogResponse(
              id: 13, workoutExerciseId: 4, setNumber: 3, completedAt: Date(), weight: 70, reps: 8,
              durationSeconds: 39, distance: 0, calories: 10),
          ]
        ),
        WorkoutExerciseResponse(
          id: 5,
          workoutSessionId: 1,
          exercise: ExerciseResponse(
            id: 5, name: "Overhead Tricep Extension", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 14, workoutExerciseId: 5, setNumber: 1, completedAt: Date(), weight: 55, reps: 12,
              durationSeconds: 36, distance: 0, calories: 9),
            SetLogResponse(
              id: 15, workoutExerciseId: 5, setNumber: 2, completedAt: Date(), weight: 60, reps: 10,
              durationSeconds: 38, distance: 0, calories: 10),
          ]
        ),
      ]
    ),
    lastWorkout: nil,
    currentWeight: "82.1",
    weightChange: "-0.3",
    streak: 1,
    streakPercentile: 50,
    weeklyWorkoutCount: 1,
    weeklyTotalVolume: "4.2 K",
    weeklyCaloriesBurned: "280 cal",
    weeklyAvgDuration: "45 min",
    weeklyPersonalRecords: ["Bench Press 205 lbs"],
    weeklyExerciseVariety: 5
  )

  /// Scenario 3: Active user with full workout history
  static let fullData = HomeScreenData(
    greeting: "Keep it up!",
    weekProgress: "You've hit 5 workouts this week. Nice work!",
    nextSession: WorkoutSessionResponse(
      id: 10,
      userId: 1,
      startTime: Date().addingTimeInterval(86400),
      title: "Back and Biceps",
      workoutExercises: [
        WorkoutExerciseResponse(
          id: 40,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 10, name: "Deadlift", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 100, workoutExerciseId: 40, setNumber: 1, completedAt: Date(), weight: 275,
              reps: 8, durationSeconds: 55, distance: 0, calories: 18),
            SetLogResponse(
              id: 101, workoutExerciseId: 40, setNumber: 2, completedAt: Date(), weight: 305,
              reps: 5, durationSeconds: 58, distance: 0, calories: 20),
            SetLogResponse(
              id: 102, workoutExerciseId: 40, setNumber: 3, completedAt: Date(), weight: 335,
              reps: 3, durationSeconds: 62, distance: 0, calories: 22),
            SetLogResponse(
              id: 103, workoutExerciseId: 40, setNumber: 4, completedAt: Date(), weight: 305,
              reps: 5, durationSeconds: 60, distance: 0, calories: 20),
          ]
        ),
        WorkoutExerciseResponse(
          id: 41,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 11, name: "Barbell Row", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 104, workoutExerciseId: 41, setNumber: 1, completedAt: Date(), weight: 185,
              reps: 10, durationSeconds: 45, distance: 0, calories: 14),
            SetLogResponse(
              id: 105, workoutExerciseId: 41, setNumber: 2, completedAt: Date(), weight: 205,
              reps: 8, durationSeconds: 48, distance: 0, calories: 15),
            SetLogResponse(
              id: 106, workoutExerciseId: 41, setNumber: 3, completedAt: Date(), weight: 225,
              reps: 6, durationSeconds: 50, distance: 0, calories: 16),
            SetLogResponse(
              id: 107, workoutExerciseId: 41, setNumber: 4, completedAt: Date(), weight: 205,
              reps: 8, durationSeconds: 48, distance: 0, calories: 15),
          ]
        ),
        WorkoutExerciseResponse(
          id: 42,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 12, name: "Pull-ups", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 108, workoutExerciseId: 42, setNumber: 1, completedAt: Date(), weight: 0,
              reps: 12, durationSeconds: 40, distance: 0, calories: 10),
            SetLogResponse(
              id: 109, workoutExerciseId: 42, setNumber: 2, completedAt: Date(), weight: 25,
              reps: 8, durationSeconds: 42, distance: 0, calories: 12),
            SetLogResponse(
              id: 110, workoutExerciseId: 42, setNumber: 3, completedAt: Date(), weight: 35,
              reps: 6, durationSeconds: 44, distance: 0, calories: 13),
          ]
        ),
        WorkoutExerciseResponse(
          id: 43,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 13, name: "Lat Pulldown", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 111, workoutExerciseId: 43, setNumber: 1, completedAt: Date(), weight: 140,
              reps: 12, durationSeconds: 38, distance: 0, calories: 11),
            SetLogResponse(
              id: 112, workoutExerciseId: 43, setNumber: 2, completedAt: Date(), weight: 155,
              reps: 10, durationSeconds: 40, distance: 0, calories: 12),
            SetLogResponse(
              id: 113, workoutExerciseId: 43, setNumber: 3, completedAt: Date(), weight: 170,
              reps: 8, durationSeconds: 42, distance: 0, calories: 13),
          ]
        ),
        WorkoutExerciseResponse(
          id: 44,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 14, name: "T-Bar Row", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 114, workoutExerciseId: 44, setNumber: 1, completedAt: Date(), weight: 135,
              reps: 10, durationSeconds: 42, distance: 0, calories: 11),
            SetLogResponse(
              id: 115, workoutExerciseId: 44, setNumber: 2, completedAt: Date(), weight: 155,
              reps: 8, durationSeconds: 44, distance: 0, calories: 12),
            SetLogResponse(
              id: 116, workoutExerciseId: 44, setNumber: 3, completedAt: Date(), weight: 175,
              reps: 6, durationSeconds: 46, distance: 0, calories: 13),
          ]
        ),
        WorkoutExerciseResponse(
          id: 45,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 15, name: "Barbell Curl", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 117, workoutExerciseId: 45, setNumber: 1, completedAt: Date(), weight: 85,
              reps: 10, durationSeconds: 35, distance: 0, calories: 9),
            SetLogResponse(
              id: 118, workoutExerciseId: 45, setNumber: 2, completedAt: Date(), weight: 95,
              reps: 8, durationSeconds: 37, distance: 0, calories: 10),
            SetLogResponse(
              id: 119, workoutExerciseId: 45, setNumber: 3, completedAt: Date(), weight: 105,
              reps: 6, durationSeconds: 39, distance: 0, calories: 11),
          ]
        ),
        WorkoutExerciseResponse(
          id: 46,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 16, name: "Hammer Curl", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 120, workoutExerciseId: 46, setNumber: 1, completedAt: Date(), weight: 50,
              reps: 12, durationSeconds: 36, distance: 0, calories: 9),
            SetLogResponse(
              id: 121, workoutExerciseId: 46, setNumber: 2, completedAt: Date(), weight: 55,
              reps: 10, durationSeconds: 38, distance: 0, calories: 10),
            SetLogResponse(
              id: 122, workoutExerciseId: 46, setNumber: 3, completedAt: Date(), weight: 60,
              reps: 8, durationSeconds: 40, distance: 0, calories: 10),
          ]
        ),
        WorkoutExerciseResponse(
          id: 47,
          workoutSessionId: 10,
          exercise: ExerciseResponse(
            id: 17, name: "Concentration Curl", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 123, workoutExerciseId: 47, setNumber: 1, completedAt: Date(), weight: 35,
              reps: 12, durationSeconds: 34, distance: 0, calories: 8),
            SetLogResponse(
              id: 124, workoutExerciseId: 47, setNumber: 2, completedAt: Date(), weight: 40,
              reps: 10, durationSeconds: 36, distance: 0, calories: 9),
          ]
        ),
      ]
    ),
    lastWorkout: WorkoutSessionResponse(
      id: 9,
      userId: 1,
      startTime: Date().addingTimeInterval(-86400),
      endTime: Date().addingTimeInterval(-86400 + 3780),
      notes:
        "Pushed hard on squats today. Form felt solid throughout all sets. Need to focus more on depth next time.",
      title: "Leg Day",
      workoutExercises: [
        WorkoutExerciseResponse(
          id: 30,
          workoutSessionId: 9,
          exercise: ExerciseResponse(
            id: 20, name: "Squat", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 70, workoutExerciseId: 30, setNumber: 1,
              completedAt: Date().addingTimeInterval(-86400), weight: 225, reps: 10,
              durationSeconds: 50, distance: 0, calories: 16),
            SetLogResponse(
              id: 71, workoutExerciseId: 30, setNumber: 2,
              completedAt: Date().addingTimeInterval(-86400), weight: 275, reps: 8,
              durationSeconds: 54, distance: 0, calories: 18),
            SetLogResponse(
              id: 72, workoutExerciseId: 30, setNumber: 3,
              completedAt: Date().addingTimeInterval(-86400), weight: 315, reps: 5,
              durationSeconds: 58, distance: 0, calories: 20),
            SetLogResponse(
              id: 73, workoutExerciseId: 30, setNumber: 4,
              completedAt: Date().addingTimeInterval(-86400), weight: 335, reps: 3,
              durationSeconds: 62, distance: 0, calories: 22),
            SetLogResponse(
              id: 74, workoutExerciseId: 30, setNumber: 5,
              completedAt: Date().addingTimeInterval(-86400), weight: 275, reps: 8,
              durationSeconds: 56, distance: 0, calories: 18),
          ]
        ),
        WorkoutExerciseResponse(
          id: 31,
          workoutSessionId: 9,
          exercise: ExerciseResponse(
            id: 21, name: "Romanian Deadlift", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 75, workoutExerciseId: 31, setNumber: 1,
              completedAt: Date().addingTimeInterval(-86400), weight: 185, reps: 10,
              durationSeconds: 45, distance: 0, calories: 14),
            SetLogResponse(
              id: 76, workoutExerciseId: 31, setNumber: 2,
              completedAt: Date().addingTimeInterval(-86400), weight: 205, reps: 8,
              durationSeconds: 48, distance: 0, calories: 15),
            SetLogResponse(
              id: 77, workoutExerciseId: 31, setNumber: 3,
              completedAt: Date().addingTimeInterval(-86400), weight: 225, reps: 6,
              durationSeconds: 50, distance: 0, calories: 16),
          ]
        ),
        WorkoutExerciseResponse(
          id: 32,
          workoutSessionId: 9,
          exercise: ExerciseResponse(
            id: 22, name: "Leg Press", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 78, workoutExerciseId: 32, setNumber: 1,
              completedAt: Date().addingTimeInterval(-86400), weight: 360, reps: 12,
              durationSeconds: 48, distance: 0, calories: 15),
            SetLogResponse(
              id: 79, workoutExerciseId: 32, setNumber: 2,
              completedAt: Date().addingTimeInterval(-86400), weight: 410, reps: 10,
              durationSeconds: 50, distance: 0, calories: 17),
            SetLogResponse(
              id: 80, workoutExerciseId: 32, setNumber: 3,
              completedAt: Date().addingTimeInterval(-86400), weight: 450, reps: 8,
              durationSeconds: 52, distance: 0, calories: 18),
          ]
        ),
        WorkoutExerciseResponse(
          id: 33,
          workoutSessionId: 9,
          exercise: ExerciseResponse(
            id: 23, name: "Leg Curl", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 81, workoutExerciseId: 33, setNumber: 1,
              completedAt: Date().addingTimeInterval(-86400), weight: 90, reps: 12,
              durationSeconds: 38, distance: 0, calories: 10),
            SetLogResponse(
              id: 82, workoutExerciseId: 33, setNumber: 2,
              completedAt: Date().addingTimeInterval(-86400), weight: 100, reps: 10,
              durationSeconds: 40, distance: 0, calories: 11),
            SetLogResponse(
              id: 83, workoutExerciseId: 33, setNumber: 3,
              completedAt: Date().addingTimeInterval(-86400), weight: 110, reps: 8,
              durationSeconds: 42, distance: 0, calories: 11),
          ]
        ),
        WorkoutExerciseResponse(
          id: 34,
          workoutSessionId: 9,
          exercise: ExerciseResponse(
            id: 24, name: "Leg Extension", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 84, workoutExerciseId: 34, setNumber: 1,
              completedAt: Date().addingTimeInterval(-86400), weight: 130, reps: 12,
              durationSeconds: 38, distance: 0, calories: 10),
            SetLogResponse(
              id: 85, workoutExerciseId: 34, setNumber: 2,
              completedAt: Date().addingTimeInterval(-86400), weight: 145, reps: 10,
              durationSeconds: 40, distance: 0, calories: 11),
            SetLogResponse(
              id: 86, workoutExerciseId: 34, setNumber: 3,
              completedAt: Date().addingTimeInterval(-86400), weight: 160, reps: 8,
              durationSeconds: 42, distance: 0, calories: 12),
          ]
        ),
        WorkoutExerciseResponse(
          id: 35,
          workoutSessionId: 9,
          exercise: ExerciseResponse(
            id: 25, name: "Calf Raise", measurementType: .reps, isSystemDefined: true),
          setLogs: [
            SetLogResponse(
              id: 87, workoutExerciseId: 35, setNumber: 1,
              completedAt: Date().addingTimeInterval(-86400), weight: 180, reps: 15,
              durationSeconds: 42, distance: 0, calories: 11),
            SetLogResponse(
              id: 88, workoutExerciseId: 35, setNumber: 2,
              completedAt: Date().addingTimeInterval(-86400), weight: 200, reps: 12,
              durationSeconds: 44, distance: 0, calories: 12),
            SetLogResponse(
              id: 89, workoutExerciseId: 35, setNumber: 3,
              completedAt: Date().addingTimeInterval(-86400), weight: 220, reps: 10,
              durationSeconds: 46, distance: 0, calories: 13),
            SetLogResponse(
              id: 90, workoutExerciseId: 35, setNumber: 4,
              completedAt: Date().addingTimeInterval(-86400), weight: 200, reps: 12,
              durationSeconds: 44, distance: 0, calories: 12),
          ]
        ),
      ]
    ),
    currentWeight: "81.2",
    weightChange: "-1.2",
    streak: 5,
    streakPercentile: 92,
    weeklyWorkoutCount: 5,
    weeklyTotalVolume: "28.7 K",
    weeklyCaloriesBurned: "2840 cal",
    weeklyAvgDuration: "58 min",
    weeklyPersonalRecords: ["Deadlift 335 lbs", "Squat 335 lbs", "Bench Press 205 lbs"],
    weeklyExerciseVariety: 15
  )
}

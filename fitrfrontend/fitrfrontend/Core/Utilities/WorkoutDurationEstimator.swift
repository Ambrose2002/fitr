import Foundation

struct WorkoutDurationEstimator {
  private static let minimumActiveSetSeconds = 30
  private static let interExerciseTransitionSeconds = 45

  private static let repsSecondsPerRep = 4
  private static let repsAndWeightSecondsPerRep = 5
  private static let repsAndTimeSecondsPerRep = 4

  private static let repsRestSeconds = 75
  private static let repsAndWeightRestSeconds = 90
  private static let repsAndTimeRestSeconds = 75
  private static let timeRestSeconds = 60
  private static let timeAndWeightRestSeconds = 60
  private static let distanceAndTimeRestSeconds = 45
  private static let caloriesAndTimeRestSeconds = 45
  private static let defaultRestSeconds = 60

  private static let standardSetupSeconds = 20
  private static let weightedSetupSeconds = 30

  static func estimatedDurationSeconds(for exercises: [EnrichedPlanExercise]) -> Int {
    guard !exercises.isEmpty else { return 0 }

    let exerciseSeconds = exercises.reduce(0) { partialResult, exercise in
      partialResult + estimatedDurationSeconds(for: exercise)
    }
    let transitionSeconds = max(exercises.count - 1, 0) * interExerciseTransitionSeconds
    return exerciseSeconds + transitionSeconds
  }

  static func estimatedMinutes(for exercises: [EnrichedPlanExercise]) -> Int {
    let totalSeconds = estimatedDurationSeconds(for: exercises)
    guard totalSeconds > 0 else { return 0 }
    return Int(ceil(Double(totalSeconds) / 60.0))
  }

  private static func estimatedDurationSeconds(for exercise: EnrichedPlanExercise) -> Int {
    let sets = max(exercise.targetSets, 1)
    let activeSetSeconds = activeSetSeconds(for: exercise)
    let restBetweenSetsSeconds = restBetweenSetsSeconds(for: exercise)
    let setupSeconds = setupSeconds(for: exercise)
    let restIntervals = max(sets - 1, 0)

    return setupSeconds + (sets * activeSetSeconds) + (restIntervals * restBetweenSetsSeconds)
  }

  private static func activeSetSeconds(for exercise: EnrichedPlanExercise) -> Int {
    let repsBasedSeconds = max(minimumActiveSetSeconds, exercise.targetReps * repsSecondsPerRep)
    let weightedRepsSeconds = max(
      minimumActiveSetSeconds,
      exercise.targetReps * repsAndWeightSecondsPerRep
    )
    let repsAndTimeSeconds = max(
      minimumActiveSetSeconds,
      max(exercise.targetDurationSeconds, exercise.targetReps * repsAndTimeSecondsPerRep)
    )
    let timedSeconds = max(minimumActiveSetSeconds, exercise.targetDurationSeconds)

    switch exercise.measurementType {
    case .some(.reps):
      return repsBasedSeconds
    case .some(.repsAndWeight):
      return weightedRepsSeconds
    case .some(.repsAndTime):
      return repsAndTimeSeconds
    case .some(.time):
      return timedSeconds
    case .some(.timeAndWeight):
      return timedSeconds
    case .some(.distanceAndTime):
      return timedSeconds
    case .some(.caloriesAndTime):
      return timedSeconds
    case .none:
      return max(minimumActiveSetSeconds, max(exercise.targetDurationSeconds, exercise.targetReps * repsSecondsPerRep))
    }
  }

  private static func restBetweenSetsSeconds(for exercise: EnrichedPlanExercise) -> Int {
    switch exercise.measurementType {
    case .some(.reps):
      return repsRestSeconds
    case .some(.repsAndWeight):
      return repsAndWeightRestSeconds
    case .some(.repsAndTime):
      return repsAndTimeRestSeconds
    case .some(.time):
      return timeRestSeconds
    case .some(.timeAndWeight):
      return timeAndWeightRestSeconds
    case .some(.distanceAndTime):
      return distanceAndTimeRestSeconds
    case .some(.caloriesAndTime):
      return caloriesAndTimeRestSeconds
    case .none:
      return defaultRestSeconds
    }
  }

  private static func setupSeconds(for exercise: EnrichedPlanExercise) -> Int {
    switch exercise.measurementType {
    case .some(.repsAndWeight), .some(.timeAndWeight):
      return weightedSetupSeconds
    case .some, .none:
      return standardSetupSeconds
    }
  }
}

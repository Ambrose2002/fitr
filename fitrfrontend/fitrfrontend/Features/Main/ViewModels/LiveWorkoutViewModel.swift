//
//  LiveWorkoutViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/2/26.
//

internal import Combine
import Foundation

struct LiveWorkoutMetricSnapshot: Equatable {
  let reps: Int?
  let weight: Float?
  let durationSeconds: Int?
  let distance: Float?
  let calories: Float?

  init(
    reps: Int? = nil,
    weight: Float? = nil,
    durationSeconds: Int? = nil,
    distance: Float? = nil,
    calories: Float? = nil
  ) {
    self.reps = reps
    self.weight = weight
    self.durationSeconds = durationSeconds
    self.distance = distance
    self.calories = calories
  }

  init(setLog: SetLogResponse) {
    self.reps = setLog.reps > 0 ? setLog.reps : nil
    self.weight = setLog.weight > 0 ? setLog.weight : nil
    self.durationSeconds = setLog.durationSeconds.map(Int.init)
    self.distance = setLog.distance > 0 ? setLog.distance : nil
    self.calories = setLog.calories > 0 ? setLog.calories : nil
  }

  init(template: LiveWorkoutTargetTemplate?) {
    guard let template else {
      self.init()
      return
    }

    self.init(
      reps: template.reps > 0 ? template.reps : nil,
      weight: template.weight > 0 ? template.weight : nil,
      durationSeconds: template.durationSeconds > 0 ? template.durationSeconds : nil,
      distance: template.distance > 0 ? template.distance : nil,
      calories: template.calories > 0 ? template.calories : nil
    )
  }
}

enum LiveWorkoutSetStatus: Equatable {
  case planned
  case logged
  case extra
}

struct LiveWorkoutSetState: Identifiable, Equatable {
  let id: String
  let setNumber: Int
  let targetValues: LiveWorkoutMetricSnapshot?
  let actualValues: LiveWorkoutMetricSnapshot?
  let status: LiveWorkoutSetStatus
  let setLogId: Int64?
}

struct LiveWorkoutExerciseState: Identifiable {
  let id: String
  let workoutExerciseId: Int64?
  let exercise: ExerciseResponse
  let source: LiveWorkoutExerciseSource
  let targetTemplate: LiveWorkoutTargetTemplate?
  let rows: [LiveWorkoutSetState]

  var loggedSetCount: Int {
    rows.filter { $0.status == .logged || $0.status == .extra }.count
  }

  var targetSetCount: Int {
    max(targetTemplate?.sets ?? 0, rows.filter { $0.status == .planned || $0.status == .logged }.count)
  }

  var hasLoggedSets: Bool {
    loggedSetCount > 0
  }

  var canRemove: Bool {
    source == .adHoc && !hasLoggedSets
  }
}

struct LiveWorkoutSetEditorContext: Identifiable {
  let id: String
  let exerciseStateId: String
  let exercise: ExerciseResponse
  let workoutExerciseId: Int64?
  let setLogId: Int64?
  let setNumber: Int
  let targetValues: LiveWorkoutMetricSnapshot?
  let suggestedValues: LiveWorkoutMetricSnapshot
  let isExtra: Bool
}

struct LiveWorkoutSetDraft {
  let reps: Int?
  let weight: Float?
  let durationSeconds: Int64?
  let distance: Float?
  let calories: Float?
}

@MainActor
final class LiveWorkoutViewModel: ObservableObject {
  private let maxSetNumber = 100

  @Published var workout: WorkoutSessionResponse?
  @Published var availableExercises: [ExerciseResponse] = []
  @Published var exerciseStates: [LiveWorkoutExerciseState] = []
  @Published var activeSetEditor: LiveWorkoutSetEditorContext?
  @Published var isLoading = true
  @Published var isSubmitting = false
  @Published var errorMessage: String?
  @Published var showEditSessionSheet = false
  @Published var sessionEditDraft = WorkoutSessionEditDraft()
  @Published var sessionEditBaselineDraft = WorkoutSessionEditDraft()
  @Published var availableLocations: [LocationResponse] = []
  @Published var isLoadingLocations = false
  @Published var isSavingSessionEdits = false
  @Published var locationLoadErrorMessage: String?
  @Published var sessionEditErrorMessage: String?
  @Published var showAddExerciseSheet = false
  @Published var showFinishSheet = false
  @Published var requestedScrollToExerciseId: String?
  @Published var restTimerEndsAt: Date?
  @Published var currentDate = Date()

  let context: ActiveWorkoutContext

  private let sessionStore: SessionStore
  private let workoutsService = WorkoutsService()
  private let locationsService = LocationsService()
  private let workoutPlanService = WorkoutPlanService()
  private var timerCancellable: AnyCancellable?
  private var hasLoadedLocationsForEditing = false
  private var preserveErrorOnNextSetEditorDismiss = false

  init(context: ActiveWorkoutContext, sessionStore: SessionStore) {
    self.context = context
    self.sessionStore = sessionStore
    self.restTimerEndsAt = context.restTimerEndsAt
    configureTimer()
  }

  deinit {
    timerCancellable?.cancel()
  }

  var titleText: String {
    let trimmed = workout?.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? context.sessionTitle : trimmed
  }

  var planSummaryTitle: String {
    titleText
  }

  var planSummarySubtitle: String {
    if context.origin.isPlanned {
      let completed = completedPlannedExerciseCount
      let total = max(context.plannedExercises.count, 1)
      return "\(completed) of \(total) exercises touched"
    }
    let count = completedExerciseCount
    return count == 0 ? "Build your workout as you go" : "\(count) exercises completed"
  }

  var canViewPlan: Bool {
    context.origin.isPlanned && context.origin.planId != nil
  }

  var completedExerciseCount: Int {
    exerciseStates.filter(\.hasLoggedSets).count
  }

  var completedPlannedExerciseCount: Int {
    exerciseStates
      .filter { $0.source == .planned && $0.hasLoggedSets }
      .count
  }

  var skippedPlannedSetCount: Int {
    exerciseStates
      .filter { $0.source == .planned }
      .reduce(into: 0) { partialResult, state in
        partialResult += state.rows.filter { $0.status == .planned }.count
      }
  }

  var addedExerciseCount: Int {
    exerciseStates.filter { $0.source == .adHoc }.count
  }

  var elapsedText: String {
    let startDate = workout?.startTime ?? context.startedAt
    let seconds = max(Int(currentDate.timeIntervalSince(startDate)), 0)
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
  }

  var restCountdownText: String {
    guard let restTimerEndsAt else {
      return "Ready"
    }

    let remaining = max(Int(restTimerEndsAt.timeIntervalSince(currentDate)), 0)
    if remaining == 0 {
      return "Ready"
    }

    let minutes = remaining / 60
    let seconds = remaining % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }

  var hasActiveRestTimer: Bool {
    guard let restTimerEndsAt else {
      return false
    }

    return restTimerEndsAt > currentDate
  }

  var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  var preferredDistanceUnit: Unit {
    sessionStore.userProfile?.preferredDistanceUnit ?? .km
  }

  func load() async {
    isLoading = true
    errorMessage = nil

    do {
      async let workoutRequest = workoutsService.fetchWorkoutSession(id: context.workoutId)
      async let catalogRequest = workoutPlanService.getAllExercises(systemOnly: false)
      let (fetchedWorkout, fetchedCatalog) = try await (workoutRequest, catalogRequest)
      workout = fetchedWorkout
      availableExercises = fetchedCatalog
      let ignoredInvalidSetLogs = rebuildExerciseStates()
      applySuccessfulReloadMessage(ignoredInvalidSetLogs: ignoredInvalidSetLogs)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to load the active workout."
    }

    isLoading = false
  }

  func reloadSession() async {
    do {
      workout = try await workoutsService.fetchWorkoutSession(id: context.workoutId)
      let ignoredInvalidSetLogs = rebuildExerciseStates()
      applySuccessfulReloadMessage(ignoredInvalidSetLogs: ignoredInvalidSetLogs)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to refresh the active workout."
    }
  }

  func presentSetEditor(exerciseId: String, rowId: String) {
    guard
      let exerciseState = exerciseStates.first(where: { $0.id == exerciseId }),
      let row = exerciseState.rows.first(where: { $0.id == rowId })
    else {
      return
    }

    let previousLoggedRow = exerciseState.rows
      .filter { $0.setNumber < row.setNumber && ($0.status == .logged || $0.status == .extra) }
      .sorted { $0.setNumber < $1.setNumber }
      .last

    let suggestedValues = row.actualValues
      ?? previousLoggedRow?.actualValues
      ?? row.targetValues
      ?? LiveWorkoutMetricSnapshot(template: exerciseState.targetTemplate)

    guard (1...maxSetNumber).contains(row.setNumber) else {
      Task {
        await recoverFromEditorOutOfSync(
          message: "This workout had an invalid set entry and was reloaded."
        )
      }
      return
    }

    clearScreenErrorMessage()
    activeSetEditor = LiveWorkoutSetEditorContext(
      id: "\(exerciseState.id)-\(row.setNumber)-\(row.setLogId ?? -1)",
      exerciseStateId: exerciseState.id,
      exercise: exerciseState.exercise,
      workoutExerciseId: exerciseState.workoutExerciseId,
      setLogId: row.setLogId,
      setNumber: row.setNumber,
      targetValues: row.targetValues,
      suggestedValues: suggestedValues,
      isExtra: row.status == .extra
    )
  }

  func presentExtraSetEditor(for exerciseId: String) {
    guard let exerciseState = exerciseStates.first(where: { $0.id == exerciseId }) else {
      return
    }

    let nextSetNumber = (exerciseState.rows.map(\.setNumber).max() ?? 0) + 1
    guard (1...maxSetNumber).contains(nextSetNumber) else {
      errorMessage = "This exercise already has the maximum supported set count."
      preserveErrorOnNextSetEditorDismiss = false
      return
    }

    let suggestedValues = exerciseState.rows
      .filter { $0.status == .logged || $0.status == .extra }
      .sorted { $0.setNumber < $1.setNumber }
      .last?.actualValues
      ?? LiveWorkoutMetricSnapshot(template: exerciseState.targetTemplate)

    clearScreenErrorMessage()
    activeSetEditor = LiveWorkoutSetEditorContext(
      id: "\(exerciseState.id)-extra-\(nextSetNumber)",
      exerciseStateId: exerciseState.id,
      exercise: exerciseState.exercise,
      workoutExerciseId: exerciseState.workoutExerciseId,
      setLogId: nil,
      setNumber: nextSetNumber,
      targetValues: nil,
      suggestedValues: suggestedValues,
      isExtra: true
    )
  }

  func saveSet(editorId: String, draft: LiveWorkoutSetDraft) async {
    guard !isSubmitting else {
      return
    }

    guard let editorContext = activeSetEditor else {
      await recoverFromEditorOutOfSync()
      return
    }

    #if DEBUG
      debugPrint(
        "LiveWorkout saveSet",
        "submittedEditorId:", editorId,
        "activeEditorId:", editorContext.id,
        "activeSetNumber:", editorContext.setNumber,
        "resolvedSetNumber:", editorContext.setNumber
      )
    #endif

    guard editorContext.id == editorId else {
      #if DEBUG
        assertionFailure("Live workout editor/save mismatch")
      #endif
      await recoverFromEditorOutOfSync()
      return
    }

    guard exerciseStates.contains(where: { $0.id == editorContext.exerciseStateId }) else {
      await recoverFromEditorOutOfSync()
      return
    }

    guard (1...maxSetNumber).contains(editorContext.setNumber) else {
      #if DEBUG
        assertionFailure("Live workout editor had invalid set number")
      #endif
      await recoverFromEditorOutOfSync()
      return
    }

    let request = CreateSingleSetLogRequest(
      setNumber: editorContext.setNumber,
      reps: draft.reps,
      weight: draft.weight,
      durationSeconds: draft.durationSeconds,
      distance: draft.distance,
      calories: draft.calories
    )

    isSubmitting = true
    clearScreenErrorMessage()

    var workoutExerciseId = editorContext.workoutExerciseId
    var createdWorkoutExerciseId: Int64?

    do {
      if workoutExerciseId == nil {
        let createdExercise = try await workoutsService.addWorkoutExercise(
          workoutId: context.workoutId,
          request: CreateWorkoutExerciseRequest(exerciseId: editorContext.exercise.id)
        )
        workoutExerciseId = createdExercise.id
        createdWorkoutExerciseId = createdExercise.id
      }

      guard let workoutExerciseId else {
        throw URLError(.badURL)
      }

      if let setLogId = editorContext.setLogId {
        _ = try await workoutsService.updateSetLog(
          workoutExerciseId: workoutExerciseId,
          setLogId: setLogId,
          request: request
        )
      } else {
        _ = try await workoutsService.createSetLog(
          workoutExerciseId: workoutExerciseId,
          request: request
        )
      }

      restTimerEndsAt = Date().addingTimeInterval(90)
      clearScreenErrorMessage()
      self.activeSetEditor = nil
      await reloadSession()
      requestedScrollToExerciseId = editorContext.exerciseStateId
    } catch let apiError as APIErrorResponse {
      if let createdWorkoutExerciseId {
        await preserveCreatedWorkoutExerciseOnFailedSave(
          editorContext: editorContext,
          workoutExerciseId: createdWorkoutExerciseId
        )
      }
      errorMessage = apiError.message
      preserveErrorOnNextSetEditorDismiss = true
    } catch {
      if let createdWorkoutExerciseId {
        await preserveCreatedWorkoutExerciseOnFailedSave(
          editorContext: editorContext,
          workoutExerciseId: createdWorkoutExerciseId
        )
      }
      errorMessage = "Failed to save that set."
      preserveErrorOnNextSetEditorDismiss = true
    }

    isSubmitting = false
  }

  func presentAddExercisePicker() {
    clearScreenErrorMessage()
    showAddExerciseSheet = true
  }

  func presentEditSession() {
    guard let workout else {
      return
    }

    let draft = WorkoutSessionEditDraft(workout: workout)
    sessionEditDraft = draft
    sessionEditBaselineDraft = draft
    sessionEditErrorMessage = nil
    showEditSessionSheet = true

    Task {
      await loadLocationsForEditingIfNeeded()
    }
  }

  func dismissEditSession() {
    showEditSessionSheet = false
    sessionEditErrorMessage = nil
  }

  func loadLocationsForEditingIfNeeded() async {
    guard !isLoadingLocations, !hasLoadedLocationsForEditing else {
      return
    }

    isLoadingLocations = true
    locationLoadErrorMessage = nil

    defer {
      isLoadingLocations = false
    }

    do {
      availableLocations = try await locationsService.fetchLocations()
      hasLoadedLocationsForEditing = true
    } catch {
      locationLoadErrorMessage = "Couldn't load saved locations. You can still update title and notes."
    }
  }

  func saveSessionEdits() async -> WorkoutSessionResponse? {
    guard !isSavingSessionEdits, let workout else {
      return nil
    }

    let trimmedTitle = sessionEditDraft.trimmedTitle
    guard !trimmedTitle.isEmpty else {
      sessionEditErrorMessage = "Enter a workout title."
      return nil
    }

    guard sessionEditDraft.hasChanges(comparedTo: sessionEditBaselineDraft) else {
      return nil
    }

    isSavingSessionEdits = true
    sessionEditErrorMessage = nil

    defer {
      isSavingSessionEdits = false
    }

    let trimmedNotes = sessionEditDraft.trimmedNotes

    do {
      let updatedWorkout = try await workoutsService.updateWorkoutSession(
        id: workout.id,
        request: CreateWorkoutSessionRequest(
          locationId: sessionEditDraft.selectedLocationId,
          notes: trimmedNotes.isEmpty ? "" : trimmedNotes,
          endTime: nil,
          title: trimmedTitle
        )
      )

      self.workout = updatedWorkout
      let updatedDraft = WorkoutSessionEditDraft(workout: updatedWorkout)
      sessionEditDraft = updatedDraft
      sessionEditBaselineDraft = updatedDraft
      sessionEditErrorMessage = nil
      showEditSessionSheet = false
      return updatedWorkout
    } catch let apiError as APIErrorResponse {
      sessionEditErrorMessage = apiError.message
      return nil
    } catch {
      sessionEditErrorMessage = "Failed to save your changes."
      return nil
    }
  }

  func handleSetEditorDismissed() {
    guard !isSubmitting else {
      return
    }

    if !preserveErrorOnNextSetEditorDismiss {
      errorMessage = nil
    }

    preserveErrorOnNextSetEditorDismiss = false
  }

  func addExercise(_ exercise: ExerciseResponse) async {
    if let existingExercise = exerciseStates.first(where: { $0.exercise.id == exercise.id }) {
      requestedScrollToExerciseId = existingExercise.id
      errorMessage = "That exercise is already in this workout. Add another set instead."
      preserveErrorOnNextSetEditorDismiss = false
      showAddExerciseSheet = false
      return
    }

    do {
      _ = try await workoutsService.addWorkoutExercise(
        workoutId: context.workoutId,
        request: CreateWorkoutExerciseRequest(exerciseId: exercise.id)
      )
      showAddExerciseSheet = false
      await reloadSession()
      requestedScrollToExerciseId = exerciseStateIdentifier(for: exercise.id)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to add the exercise."
    }
  }

  func removeExercise(_ exerciseState: LiveWorkoutExerciseState) async {
    guard exerciseState.canRemove, let workoutExerciseId = exerciseState.workoutExerciseId else {
      return
    }

    do {
      try await workoutsService.deleteWorkoutExercise(
        workoutId: context.workoutId,
        exerciseId: workoutExerciseId
      )
      await reloadSession()
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to remove the exercise."
    }
  }

  private func configureTimer() {
    timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] currentDate in
        guard let self else {
          return
        }

        self.currentDate = currentDate
        if let restTimerEndsAt = self.restTimerEndsAt, restTimerEndsAt <= currentDate {
          self.restTimerEndsAt = nil
        }
      }
  }

  private func preserveCreatedWorkoutExerciseOnFailedSave(
    editorContext: LiveWorkoutSetEditorContext,
    workoutExerciseId: Int64
  ) async {
    activeSetEditor = LiveWorkoutSetEditorContext(
      id: editorContext.id,
      exerciseStateId: editorContext.exerciseStateId,
      exercise: editorContext.exercise,
      workoutExerciseId: workoutExerciseId,
      setLogId: editorContext.setLogId,
      setNumber: editorContext.setNumber,
      targetValues: editorContext.targetValues,
      suggestedValues: editorContext.suggestedValues,
      isExtra: editorContext.isExtra
    )
    await reloadSession()
  }

  private func clearScreenErrorMessage() {
    errorMessage = nil
    preserveErrorOnNextSetEditorDismiss = false
  }

  private func applySuccessfulReloadMessage(ignoredInvalidSetLogs: Bool) {
    guard activeSetEditor == nil else {
      return
    }

    errorMessage = ignoredInvalidSetLogs
      ? "Some invalid set history was ignored so you can keep logging."
      : nil
    preserveErrorOnNextSetEditorDismiss = false
  }

  private func recoverFromEditorOutOfSync(
    message: String = "Workout state was out of sync. The session was reloaded."
  ) async {
    activeSetEditor = nil
    preserveErrorOnNextSetEditorDismiss = false
    await reloadSession()
    errorMessage = message
  }

  private func rebuildExerciseStates() -> Bool {
    var ignoredInvalidSetLogs = false

    guard let workout else {
      exerciseStates = context.plannedExercises.map { plannedExercise in
        let builtRows = buildRows(for: nil, plannedExercise: plannedExercise)
        return LiveWorkoutExerciseState(
          id: exerciseStateIdentifier(for: plannedExercise.exerciseId),
          workoutExerciseId: nil,
          exercise: ExerciseResponse(
            id: plannedExercise.exerciseId,
            name: plannedExercise.name,
            measurementType: plannedExercise.measurementType
          ),
          source: plannedExercise.source,
          targetTemplate: plannedExercise.targetTemplate,
          rows: builtRows.rows
        )
      }
      return ignoredInvalidSetLogs
    }

    let workoutExercisesByExerciseId = workout.workoutExercises.reduce(into: [Int64: WorkoutExerciseResponse]())
    { partialResult, workoutExercise in
      partialResult[workoutExercise.exercise.id] = workoutExercise
    }

    var orderedStates: [LiveWorkoutExerciseState] = []

    for plannedExercise in context.plannedExercises {
      let workoutExercise = workoutExercisesByExerciseId[plannedExercise.exerciseId]
      let builtRows = buildRows(for: workoutExercise, plannedExercise: plannedExercise)
      ignoredInvalidSetLogs = ignoredInvalidSetLogs || builtRows.ignoredInvalidSetLogs
      orderedStates.append(
        LiveWorkoutExerciseState(
          id: exerciseStateIdentifier(for: plannedExercise.exerciseId),
          workoutExerciseId: workoutExercise?.id,
          exercise: workoutExercise?.exercise
            ?? ExerciseResponse(
              id: plannedExercise.exerciseId,
              name: plannedExercise.name,
              measurementType: plannedExercise.measurementType
            ),
          source: .planned,
          targetTemplate: plannedExercise.targetTemplate,
          rows: builtRows.rows
        )
      )
    }

    let plannedExerciseIds = Set(context.plannedExercises.map(\.exerciseId))
    let adHocExercises = workout.workoutExercises
      .filter { !plannedExerciseIds.contains($0.exercise.id) }
      .sorted { $0.id < $1.id }
    var adHocStates: [LiveWorkoutExerciseState] = []

    for workoutExercise in adHocExercises {
      let builtRows = buildRows(for: workoutExercise, plannedExercise: nil)
      ignoredInvalidSetLogs = ignoredInvalidSetLogs || builtRows.ignoredInvalidSetLogs
      adHocStates.append(
        LiveWorkoutExerciseState(
          id: exerciseStateIdentifier(for: workoutExercise.exercise.id),
          workoutExerciseId: workoutExercise.id,
          exercise: workoutExercise.exercise,
          source: .adHoc,
          targetTemplate: nil,
          rows: builtRows.rows
        )
      )
    }

    exerciseStates = orderedStates + adHocStates
    return ignoredInvalidSetLogs
  }

  private func buildRows(
    for workoutExercise: WorkoutExerciseResponse?,
    plannedExercise: ActiveWorkoutPlannedExercise?
  ) -> (rows: [LiveWorkoutSetState], ignoredInvalidSetLogs: Bool) {
    let sanitizedLogs = sanitizedSetLogs(from: workoutExercise?.setLogs ?? [])
    let sortedLogs = sanitizedLogs.logs

    if let plannedExercise {
      let targetSetCount = min(max(plannedExercise.targetTemplate?.sets ?? 0, 1), maxSetNumber)
      let targetValues = LiveWorkoutMetricSnapshot(template: plannedExercise.targetTemplate)
      var rows: [LiveWorkoutSetState] = []

      for setNumber in 1...targetSetCount {
        let matchingLog = sortedLogs.last { $0.setNumber == setNumber }
        rows.append(
          LiveWorkoutSetState(
            id: "\(exerciseStateIdentifier(for: plannedExercise.exerciseId))-\(setNumber)",
            setNumber: setNumber,
            targetValues: targetValues,
            actualValues: matchingLog.map(LiveWorkoutMetricSnapshot.init),
            status: matchingLog == nil ? .planned : .logged,
            setLogId: matchingLog?.id
          )
        )
      }

      let extraLogs = sortedLogs.filter { $0.setNumber > targetSetCount }
      rows.append(
        contentsOf: extraLogs.map { setLog in
          LiveWorkoutSetState(
            id: "\(exerciseStateIdentifier(for: plannedExercise.exerciseId))-\(setLog.setNumber)",
            setNumber: setLog.setNumber,
            targetValues: nil,
            actualValues: LiveWorkoutMetricSnapshot(setLog: setLog),
            status: .extra,
            setLogId: setLog.id
          )
        }
      )

      return (rows, sanitizedLogs.ignoredInvalidSetLogs)
    }

    if sortedLogs.isEmpty, let workoutExercise {
      return ([
        LiveWorkoutSetState(
          id: "\(exerciseStateIdentifier(for: workoutExercise.exercise.id))-1",
          setNumber: 1,
          targetValues: nil,
          actualValues: nil,
          status: .planned,
          setLogId: nil
        )
      ], sanitizedLogs.ignoredInvalidSetLogs)
    }

    return (
      sortedLogs.map { setLog in
        LiveWorkoutSetState(
          id: "\(exerciseStateIdentifier(for: workoutExercise?.exercise.id ?? -1))-\(setLog.setNumber)",
          setNumber: setLog.setNumber,
          targetValues: nil,
          actualValues: LiveWorkoutMetricSnapshot(setLog: setLog),
          status: .logged,
          setLogId: setLog.id
        )
      },
      sanitizedLogs.ignoredInvalidSetLogs
    )
  }

  private func exerciseStateIdentifier(for exerciseId: Int64) -> String {
    "exercise-\(exerciseId)"
  }

  private func sanitizedSetLogs(from setLogs: [SetLogResponse]) -> (
    logs: [SetLogResponse],
    ignoredInvalidSetLogs: Bool
  ) {
    let sortedLogs = setLogs.sorted {
      if $0.setNumber == $1.setNumber {
        return $0.id < $1.id
      }
      return $0.setNumber < $1.setNumber
    }

    var latestLogBySetNumber: [Int: SetLogResponse] = [:]
    var ignoredInvalidSetLogs = false

    for setLog in sortedLogs {
      guard (1...maxSetNumber).contains(setLog.setNumber) else {
        ignoredInvalidSetLogs = true
        continue
      }

      latestLogBySetNumber[setLog.setNumber] = setLog
    }

    let logs = latestLogBySetNumber.values.sorted {
      if $0.setNumber == $1.setNumber {
        return $0.id < $1.id
      }
      return $0.setNumber < $1.setNumber
    }

    return (logs, ignoredInvalidSetLogs)
  }
}

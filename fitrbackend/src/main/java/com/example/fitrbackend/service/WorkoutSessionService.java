package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.CreateSetLogRequest;
import com.example.fitrbackend.dto.CreateSingleSetLogRequest;
import com.example.fitrbackend.dto.CreateWorkoutExerciseReqeust;
import com.example.fitrbackend.dto.ExerciseResponse;
import com.example.fitrbackend.dto.SetLogResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.model.Exercise;
import com.example.fitrbackend.model.MeasurementType;
import com.example.fitrbackend.model.SetLog;
import com.example.fitrbackend.repository.ExerciseRepository;
import com.example.fitrbackend.repository.SetLogRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fitrbackend.dto.CreateWorkoutSessionRequest;
import com.example.fitrbackend.dto.WorkoutExerciseResponse;
import com.example.fitrbackend.dto.WorkoutSessionResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.Location;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.WorkoutExercise;
import com.example.fitrbackend.model.WorkoutSession;
import com.example.fitrbackend.repository.LocationRepository;
import com.example.fitrbackend.repository.UserRepository;
import com.example.fitrbackend.repository.WorkoutExerciseRepository;
import com.example.fitrbackend.repository.WorkoutSessionRepository;

@Service
public class WorkoutSessionService {
    private static final long MAX_SET_NUMBER = 100L;
    private static final long MAX_REPS = 1000L;
    private static final long MAX_DURATION_SECONDS = 21_600L;
    private static final float MAX_WEIGHT = 10_000f;
    private static final float MAX_DISTANCE = 1_000f;
    private static final float MAX_CALORIES = 50_000f;

    private final WorkoutSessionRepository workoutSessionRepo;
    private final UserRepository userRepo;
    private final LocationRepository locationRepo;
    private final WorkoutExerciseRepository workoutExerciseRepo;
    private final ExerciseRepository exerciseRepo;
    private final SetLogRepository setLogRepo;

    public WorkoutSessionService(WorkoutSessionRepository workoutSessionRepo, UserRepository userRepo,
            LocationRepository locationRepo, WorkoutExerciseRepository workoutExerciseRepo,
            SetLogRepository setLogRepo, ExerciseRepository exerciseRepo) {
        this.workoutSessionRepo = workoutSessionRepo;
        this.userRepo = userRepo;
        this.locationRepo = locationRepo;
        this.workoutExerciseRepo = workoutExerciseRepo;
        this.exerciseRepo = exerciseRepo;
        this.setLogRepo = setLogRepo;
    }

    public WorkoutSessionResponse createWorkoutSession(String email, CreateWorkoutSessionRequest req) {

        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        Location location = null;
        if (req.getLocationId() != null) {
            location = locationRepo.findById(req.getLocationId())
                    .orElseThrow(() -> new DataNotFoundException("location not found"));
        }
        WorkoutSession workoutSession = new WorkoutSession(user, Instant.now(), null, req.getNotes(), location);
        if (req.getEndTime() != null && !req.getEndTime().isEmpty()) {
            workoutSession.setEndTime(parseDate(req.getEndTime()));
        }

        String title = (req.getTitle() != null && !req.getTitle().isEmpty())
                ? req.getTitle()
                : generateWorkoutTitle(workoutSession.getStartTime());
        workoutSession.setTitle(title);

        WorkoutSession savedSession = workoutSessionRepo.save(workoutSession);
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(savedSession.getId());
        List<WorkoutExerciseResponse> workoutExerciseResponses = workoutExercises.stream()
                .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
        return toWorkoutSessionResponse(savedSession, workoutExerciseResponses);
    }

    public List<WorkoutSessionResponse> getWorkoutSessions(String email, String fromDate, String toDate,
            Integer limit) {
        List<WorkoutSession> workoutSessions = workoutSessionRepo.findByUserEmail(email);

        if (fromDate != null && !fromDate.isEmpty()) {
            Instant fromDateInstant = parseDate(fromDate);
            workoutSessions = workoutSessions.stream().filter(w -> w.getStartTime().isAfter(fromDateInstant)).toList();
        }

        if (toDate != null && !toDate.isEmpty()) {
            Instant toDateInstant = parseDate(toDate);
            workoutSessions = workoutSessions.stream().filter(w -> w.getStartTime().isBefore(toDateInstant)).toList();
        }

        // Sort by startTime descending (newest first)
        workoutSessions = workoutSessions.stream()
                .sorted((a, b) -> b.getStartTime().compareTo(a.getStartTime()))
                .toList();

        if (limit != null && limit > 0) {
            return workoutSessions.stream().limit(limit).map(ws -> {
                List<WorkoutExercise> exercises = workoutExerciseRepo.findByWorkoutSessionId(ws.getId());
                List<WorkoutExerciseResponse> exerciseResponses = exercises.stream()
                        .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId())))
                        .toList();
                return toWorkoutSessionResponse(ws, exerciseResponses);
            }).toList();
        }
        return workoutSessions.stream().map(ws -> {
            List<WorkoutExercise> exercises = workoutExerciseRepo.findByWorkoutSessionId(ws.getId());
            List<WorkoutExerciseResponse> exerciseResponses = exercises.stream()
                    .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
            return toWorkoutSessionResponse(ws, exerciseResponses);
        }).toList();
    }

    public WorkoutSessionResponse getActiveWorkoutSession(String email) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }

        List<WorkoutSession> activeWorkouts = workoutSessionRepo.findActiveByUserEmail(email);
        if (activeWorkouts.isEmpty()) {
            return null;
        }

        WorkoutSession workoutSession = activeWorkouts.get(0);
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(workoutSession.getId());
        List<WorkoutExerciseResponse> workoutExerciseResponses = workoutExercises.stream()
                .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
        return toWorkoutSessionResponse(workoutSession, workoutExerciseResponses);
    }

    public WorkoutSessionResponse getWorkoutSession(String email, Long id) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException(id, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(id, "WorkoutSession");
        }
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(
                workoutSession.getId());
        List<WorkoutExerciseResponse> workoutExerciseResponses = workoutExercises.stream()
                .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
        return toWorkoutSessionResponse(workoutSession, workoutExerciseResponses);
    }

    public WorkoutSessionResponse updateWorkoutSession(String email, Long id, CreateWorkoutSessionRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException(id, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(id, "WorkoutSession");
        }
        if (req.getNotes() != null) {
            workoutSession.setNotes(req.getNotes());
        }

        if (req.getEndTime() != null && !req.getEndTime().isEmpty()) {
            workoutSession.setEndTime(parseDate(req.getEndTime()));
        }
        if (req.getTitle() != null) {
            workoutSession.setTitle(req.getTitle());
        }
        if (req.getLocationId() != null) {
            Location location = locationRepo.findById(req.getLocationId())
                    .orElseThrow(() -> new DataNotFoundException("location not found"));
            workoutSession.setWorkoutLocation(location);
        }
        WorkoutSession savedSession = workoutSessionRepo.save(workoutSession);
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(savedSession.getId());
        List<WorkoutExerciseResponse> workoutExerciseResponses = workoutExercises.stream()
                .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
        return toWorkoutSessionResponse(savedSession, workoutExerciseResponses);
    }

    public WorkoutExerciseResponse createWorkoutExercise(String email, Long workoutId,
            CreateWorkoutExerciseReqeust req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(workoutId)
                .orElseThrow(() -> new DataNotFoundException(workoutId, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutId, "WorkoutSession");
        }
        Exercise exercise = exerciseRepo.findById(req.getExerciseId())
                .orElseThrow(() -> new DataNotFoundException(req.getExerciseId(), "Exercise"));

        List<WorkoutExercise> existingWorkoutExercises = workoutExerciseRepo.findByWorkoutSessionIdAndExerciseId(
                workoutId, req.getExerciseId());
        if (!existingWorkoutExercises.isEmpty()) {
            WorkoutExercise existingWorkoutExercise = existingWorkoutExercises.get(0);
            List<SetLog> setLogs = setLogRepo.findByWorkoutExerciseId(existingWorkoutExercise.getId());
            return toWorkoutExerciseResponse(existingWorkoutExercise, setLogs);
        }

        WorkoutExercise workoutExercise = new WorkoutExercise(workoutSession, exercise);
        WorkoutExercise savedWorkoutExercise = workoutExerciseRepo.save(workoutExercise);
        List<SetLog> setLogs = setLogRepo.findByWorkoutExerciseId(savedWorkoutExercise.getId());
        return toWorkoutExerciseResponse(savedWorkoutExercise, setLogs);
    }

    @Transactional
    public void deleteWorkoutSession(String email, Long id) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException(id, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(id, "WorkoutSession");
        }
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(id);
        for (WorkoutExercise workoutExercise : workoutExercises) {
            setLogRepo.deleteByWorkoutExerciseId(workoutExercise.getId());
        }
        if (!workoutExercises.isEmpty()) {
            workoutExerciseRepo.deleteByWorkoutSessionId(id);
        }
        workoutSessionRepo.delete(workoutSession);
    }

    public List<WorkoutExerciseResponse> getWorkoutExercises(String email, Long workoutId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(workoutId)
                .orElseThrow(() -> new DataNotFoundException(workoutId, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutId, "WorkoutSession");
        }
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(workoutId);
        return workoutExercises.stream()
                .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
    }

    @Transactional
    public void deleteWorkoutExercise(String email, Long workoutId, Long exerciseId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(workoutId)
                .orElseThrow(() -> new DataNotFoundException(workoutId, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutId, "WorkoutSession");
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(exerciseId)
                .orElseThrow(() -> new DataNotFoundException(exerciseId, "WorkoutExercise"));
        if (workoutExercise.getWorkoutSession().getId() != workoutId) {
            throw new DataNotFoundException(exerciseId, "Exercise");
        }
        setLogRepo.deleteByWorkoutExerciseId(exerciseId);
        workoutExerciseRepo.delete(workoutExercise);
    }

    public List<SetLogResponse> createSetLog(String email, Long workoutExerciseId, CreateSetLogRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId)
                .orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));

        if (!workoutExercise.getWorkoutSession().getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutExerciseId, "WorkoutExercise");
        }

        MeasurementType measurementType = workoutExercise.getExercise().getMeasurementType();

        if (req.getSets() == 0) {
            throw new DataCreationFailedException("sets is required");
        }
        int num_sets = req.getSets();
        List<SetLog> setLogs = new ArrayList<>();
        switch (measurementType) {
            case REPS:
                if (req.getAverageReps() == 0) {
                    throw new DataCreationFailedException("reps is required");
                }
                for (int i = 0; i < num_sets; i++) {
                    SetLog newLog = new SetLog();
                    newLog.setSetNumber(i + 1);
                    newLog.setReps(req.getAverageReps());
                    setLogs.add(newLog);
                }
                break;
            case TIME:
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                for (int i = 0; i < num_sets; i++) {
                    SetLog newLog = new SetLog();
                    newLog.setSetNumber(i + 1);
                    newLog.setDurationSeconds(req.getAverageDurationSeconds());
                    setLogs.add(newLog);
                }
                break;
            case REPS_AND_TIME:
                if (req.getAverageReps() == 0) {
                    throw new DataCreationFailedException("reps is required");
                }
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                for (int i = 0; i < num_sets; i++) {
                    SetLog newLog = new SetLog();
                    newLog.setSetNumber(i + 1);
                    newLog.setReps(req.getAverageReps());
                    newLog.setDurationSeconds(req.getAverageDurationSeconds());
                    setLogs.add(newLog);
                }
                break;
            case REPS_AND_WEIGHT:
                if (req.getAverageReps() == 0) {
                    throw new DataCreationFailedException("reps is required");
                }
                if (req.getAverageWeight() == 0) {
                    throw new DataCreationFailedException("weight is required");
                }
                for (int i = 0; i < num_sets; i++) {
                    SetLog newLog = new SetLog();
                    newLog.setSetNumber(i + 1);
                    newLog.setReps(req.getAverageReps());
                    newLog.setWeight(req.getAverageWeight());
                    setLogs.add(newLog);
                }
                break;
            case DISTANCE_AND_TIME:
                if (req.getAverageDistance() == 0) {
                    throw new DataCreationFailedException("distance is required");
                }
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                for (int i = 0; i < num_sets; i++) {
                    SetLog newLog = new SetLog();
                    newLog.setSetNumber(i + 1);
                    newLog.setDistance(req.getAverageDistance());
                    newLog.setDurationSeconds(req.getAverageDurationSeconds());
                    setLogs.add(newLog);
                }
                break;
            case CALORIES_AND_TIME:
                if (req.getAverageCalories() == 0) {
                    throw new DataCreationFailedException("calories is required");
                }
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                for (int i = 0; i < num_sets; i++) {
                    SetLog newLog = new SetLog();
                    newLog.setSetNumber(i + 1);
                    newLog.setCalories(req.getAverageCalories());
                    newLog.setDurationSeconds(req.getAverageDurationSeconds());
                    setLogs.add(newLog);
                }
                break;
            case TIME_AND_WEIGHT:
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                if (req.getAverageWeight() == 0) {
                    throw new DataCreationFailedException("weight is required");
                }
                for (int i = 0; i < num_sets; i++) {
                    SetLog newLog = new SetLog();
                    newLog.setSetNumber(i + 1);
                    newLog.setDurationSeconds(req.getAverageDurationSeconds());
                    newLog.setWeight(req.getAverageWeight());
                    setLogs.add(newLog);
                }
                break;
            default:
                throw new DataCreationFailedException("invalid measurement type");
        }
        List<SetLogResponse> response = new ArrayList<>();
        for (SetLog setLog : setLogs) {
            setLog.setWorkoutExercise(workoutExercise);
            setLog.setCompletedAt(Instant.now());
            response.add(toSetLogResponse(setLogRepo.save(setLog)));
        }

        return response;
    }

    public SetLogResponse createSingleSetLog(String email, Long workoutExerciseId, CreateSingleSetLogRequest req) {
        WorkoutExercise workoutExercise = requireOwnedWorkoutExercise(email, workoutExerciseId);
        int setNumber = requireSetNumber(req.getSetNumber());

        boolean hasExistingSetNumber = setLogRepo.findByWorkoutExerciseId(workoutExerciseId).stream()
                .anyMatch(existingLog -> existingLog.getSetNumber() == setNumber);
        if (hasExistingSetNumber) {
            throw new DataCreationFailedException("set number already exists");
        }

        SetLog setLog = new SetLog();
        setLog.setWorkoutExercise(workoutExercise);
        setLog.setSetNumber(setNumber);
        applySingleSetMetrics(setLog, workoutExercise.getExercise().getMeasurementType(), req);
        setLog.setCompletedAt(Instant.now());

        return toSetLogResponse(setLogRepo.save(setLog));
    }

    public SetLogResponse updateSetLog(String email, Long workoutExerciseId, Long setLogId, CreateSetLogRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId)
                .orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));

        if (!workoutExercise.getWorkoutSession().getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutExerciseId, "WorkoutExercise");
        }

        SetLog setLog = setLogRepo.findById(setLogId).orElseThrow(() -> new DataNotFoundException(setLogId, "SetLog"));
        if (setLog.getWorkoutExercise().getId() != workoutExerciseId) {
            throw new DataNotFoundException(setLogId, "SetLog");
        }

        MeasurementType measurementType = workoutExercise.getExercise().getMeasurementType();

        switch (measurementType) {
            case REPS:
                if (req.getAverageReps() == 0) {
                    throw new DataCreationFailedException("reps is required");
                }
                setLog.setReps(req.getAverageReps());
                break;
            case TIME:
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                setLog.setDurationSeconds(req.getAverageDurationSeconds());
                break;
            case REPS_AND_TIME:
                if (req.getAverageReps() == 0) {
                    throw new DataCreationFailedException("reps is required");
                }
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                setLog.setReps(req.getAverageReps());
                setLog.setDurationSeconds(req.getAverageDurationSeconds());
                break;
            case REPS_AND_WEIGHT:
                if (req.getAverageReps() == 0) {
                    throw new DataCreationFailedException("reps is required");
                }
                if (req.getAverageWeight() == 0) {
                    throw new DataCreationFailedException("weight is required");
                }
                setLog.setReps(req.getAverageReps());
                setLog.setWeight(req.getAverageWeight());
                break;
            case DISTANCE_AND_TIME:
                if (req.getAverageDistance() == 0) {
                    throw new DataCreationFailedException("distance is required");
                }
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                setLog.setDistance(req.getAverageDistance());
                setLog.setDurationSeconds(req.getAverageDurationSeconds());
                break;
            case CALORIES_AND_TIME:
                if (req.getAverageCalories() == 0) {
                    throw new DataCreationFailedException("calories is required");
                }
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                setLog.setCalories(req.getAverageCalories());
                setLog.setDurationSeconds(req.getAverageDurationSeconds());
                break;
            case TIME_AND_WEIGHT:
                if (req.getAverageDurationSeconds() == null || req.getAverageDurationSeconds() == 0) {
                    throw new DataCreationFailedException("duration is required");
                }
                if (req.getAverageWeight() == 0) {
                    throw new DataCreationFailedException("weight is required");
                }
                setLog.setDurationSeconds(req.getAverageDurationSeconds());
                setLog.setWeight(req.getAverageWeight());
                break;
            default:
                throw new DataCreationFailedException("invalid measurement type");
        }

        return toSetLogResponse(setLogRepo.save(setLog));
    }

    public SetLogResponse updateSingleSetLog(String email, Long workoutExerciseId, Long setLogId, CreateSingleSetLogRequest req) {
        WorkoutExercise workoutExercise = requireOwnedWorkoutExercise(email, workoutExerciseId);
        SetLog setLog = requireOwnedSetLog(workoutExerciseId, setLogId);
        int setNumber = requireSetNumber(req.getSetNumber());

        boolean hasConflictingSetNumber = setLogRepo.findByWorkoutExerciseId(workoutExerciseId).stream()
                .anyMatch(existingLog -> existingLog.getId() != setLogId && existingLog.getSetNumber() == setNumber);
        if (hasConflictingSetNumber) {
            throw new DataCreationFailedException("set number already exists");
        }

        setLog.setSetNumber(setNumber);
        applySingleSetMetrics(setLog, workoutExercise.getExercise().getMeasurementType(), req);
        if (setLog.getCompletedAt() == null) {
            setLog.setCompletedAt(Instant.now());
        }

        return toSetLogResponse(setLogRepo.save(setLog));
    }

    public void deleteSetLog(String email, Long workoutExerciseId, Long setLogId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId)
                .orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));
        if (!workoutExercise.getWorkoutSession().getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutExerciseId, "WorkoutExercise");
        }
        SetLog setLog = setLogRepo.findById(setLogId).orElseThrow(() -> new DataNotFoundException(setLogId, "SetLog"));
        if (setLog.getWorkoutExercise().getId() != workoutExerciseId) {
            throw new DataNotFoundException(setLogId, "SetLog");
        }
        setLogRepo.delete(setLog);
    }

    public List<SetLogResponse> getSetLogs(String email, Long workoutExerciseId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId)
                .orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));
        if (!workoutExercise.getWorkoutSession().getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutExerciseId, "WorkoutExercise");
        }
        List<SetLog> setLogs = setLogRepo.findByWorkoutExerciseId(workoutExerciseId);
        return setLogs.stream().map(this::toSetLogResponse).toList();
    }

    private WorkoutExercise requireOwnedWorkoutExercise(String email, Long workoutExerciseId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId)
                .orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));
        if (!workoutExercise.getWorkoutSession().getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutExerciseId, "WorkoutExercise");
        }
        return workoutExercise;
    }

    private SetLog requireOwnedSetLog(Long workoutExerciseId, Long setLogId) {
        SetLog setLog = setLogRepo.findById(setLogId).orElseThrow(() -> new DataNotFoundException(setLogId, "SetLog"));
        if (setLog.getWorkoutExercise().getId() != workoutExerciseId) {
            throw new DataNotFoundException(setLogId, "SetLog");
        }
        return setLog;
    }

    private void applySingleSetMetrics(SetLog setLog, MeasurementType measurementType, CreateSingleSetLogRequest req) {
        setLog.setReps(0);
        setLog.setWeight(0);
        setLog.setDurationSeconds(null);
        setLog.setDistance(0);
        setLog.setCalories(0);

        switch (measurementType) {
            case REPS:
                setLog.setReps(requireReps(req.getReps()));
                break;
            case TIME:
                setLog.setDurationSeconds(requireDurationSeconds(req.getDurationSeconds()));
                break;
            case REPS_AND_TIME:
                setLog.setReps(requireReps(req.getReps()));
                setLog.setDurationSeconds(requireDurationSeconds(req.getDurationSeconds()));
                break;
            case REPS_AND_WEIGHT:
                setLog.setReps(requireReps(req.getReps()));
                setLog.setWeight(requirePositiveFloat(req.getWeight(), MAX_WEIGHT, "weight"));
                break;
            case DISTANCE_AND_TIME:
                setLog.setDistance(requirePositiveFloat(req.getDistance(), MAX_DISTANCE, "distance"));
                setLog.setDurationSeconds(requireDurationSeconds(req.getDurationSeconds()));
                break;
            case CALORIES_AND_TIME:
                setLog.setCalories(requirePositiveFloat(req.getCalories(), MAX_CALORIES, "calories"));
                setLog.setDurationSeconds(requireDurationSeconds(req.getDurationSeconds()));
                break;
            case TIME_AND_WEIGHT:
                setLog.setDurationSeconds(requireDurationSeconds(req.getDurationSeconds()));
                setLog.setWeight(requirePositiveFloat(req.getWeight(), MAX_WEIGHT, "weight"));
                break;
            default:
                throw new DataCreationFailedException("invalid measurement type");
        }
    }

    private int requireSetNumber(Long setNumber) {
        if (setNumber == null) {
            throw new DataCreationFailedException("setNumber is required");
        }
        if (setNumber < 1 || setNumber > MAX_SET_NUMBER) {
            throw new DataCreationFailedException(
                    "setNumber must be between 1 and " + MAX_SET_NUMBER + " (received " + setNumber + ")");
        }
        return Math.toIntExact(setNumber);
    }

    private int requireReps(Long reps) {
        if (reps == null) {
            throw new DataCreationFailedException("reps is required");
        }
        if (reps < 1 || reps > MAX_REPS) {
            throw new DataCreationFailedException("reps must be between 1 and " + MAX_REPS);
        }
        return Math.toIntExact(reps);
    }

    private long requireDurationSeconds(Long durationSeconds) {
        if (durationSeconds == null) {
            throw new DataCreationFailedException("duration is required");
        }
        if (durationSeconds < 1 || durationSeconds > MAX_DURATION_SECONDS) {
            throw new DataCreationFailedException("duration must be between 1 and " + MAX_DURATION_SECONDS + " seconds");
        }
        return durationSeconds;
    }

    private float requirePositiveFloat(Float value, float maxValue, String fieldName) {
        if (value == null) {
            throw new DataCreationFailedException(fieldName + " is required");
        }
        if (value <= 0 || value > maxValue) {
            throw new DataCreationFailedException(fieldName + " must be greater than 0 and at most " + maxValue);
        }
        return value;
    }

    private Instant parseDate(String dateStr) {
        try {
            // Try parsing as ISO 8601 instant first
            return Instant.parse(dateStr);
        } catch (Exception e) {
            // Fall back to parsing as date only (e.g., 2026-01-01)
            try {
                return LocalDate.parse(dateStr).atStartOfDay().toInstant(ZoneOffset.UTC);
            } catch (Exception ex) {
                throw new DataCreationFailedException("Invalid date format");
            }
        }
    }

    private WorkoutExerciseResponse toWorkoutExerciseResponse(WorkoutExercise workoutExercise, List<SetLog> setLogs) {
        return new WorkoutExerciseResponse(
                workoutExercise.getId(),
                workoutExercise.getWorkoutSession().getId(),
                toExerciseResponse(workoutExercise.getExercise()),
                setLogs.stream().map(this::toSetLogResponse).toList());
    }

    private ExerciseResponse toExerciseResponse(Exercise exercise) {
        return new ExerciseResponse(
                exercise.getId(),
                exercise.getName(),
                exercise.getMeasurementType(),
                exercise.isSystemDefined(),
                exercise.getCreatedAt());
    }

    private SetLogResponse toSetLogResponse(SetLog setLog) {
        return new SetLogResponse(
                setLog.getId(),
                setLog.getWorkoutExercise().getId(),
                setLog.getSetNumber(),
                setLog.getCompletedAt(),
                setLog.getWeight(),
                setLog.getReps(),
                setLog.getDurationSeconds(),
                setLog.getDistance(),
                setLog.getCalories());
    }

    private WorkoutSessionResponse toWorkoutSessionResponse(WorkoutSession workoutSession,
            List<WorkoutExerciseResponse> workoutExerciseResponses) {
        Long workoutLocationId = workoutSession.getWorkoutLocation() == null
                ? null
                : workoutSession.getWorkoutLocation().getId();
        String locationName = workoutSession.getWorkoutLocation() == null
                ? null
                : workoutSession.getWorkoutLocation().getName();
        return new WorkoutSessionResponse(
                workoutSession.getId(),
                workoutSession.getUser().getId(),
                workoutLocationId,
                locationName,
                workoutSession.getStartTime(),
                workoutSession.getEndTime(),
                workoutSession.getNotes(),
                workoutSession.getTitle(),
                workoutExerciseResponses);
    }

    private String generateWorkoutTitle(Instant startTime) {
        LocalDate date = LocalDate.from(startTime.atZone(java.time.ZoneId.systemDefault()));
        java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("E MMM dd yyyy");
        return date.format(formatter) + " Workout";
    }
}

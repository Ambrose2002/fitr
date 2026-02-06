package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.CreateSetLogRequest;
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
        Location location = locationRepo.findById(req.getLocationId())
                .orElseThrow(() -> new DataNotFoundException("location not found"));
        WorkoutSession workoutSession = new WorkoutSession(user, Instant.now(), null, req.getNotes(), location);
        if (req.getEndTime() != null && !req.getEndTime().isEmpty()) {
            workoutSession.setEndTime(parseDate(req.getEndTime()));
        }
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

        if (limit != null && limit > 0) {
            return workoutSessions.stream().limit(limit).map(ws -> {
                List<WorkoutExercise> exercises = workoutExerciseRepo.findByWorkoutSessionId(ws.getId());
                List<WorkoutExerciseResponse> exerciseResponses = exercises.stream()
                        .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
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

    public WorkoutSessionResponse getWorkoutSession(String email, Long id) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(id, "WorkoutSession");
        }
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(
                workoutSession.getId());
        List<WorkoutExerciseResponse> workoutExerciseResponses = workoutExercises.stream().map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
        return toWorkoutSessionResponse(workoutSession, workoutExerciseResponses);
    }

    public WorkoutSessionResponse updateWorkoutSession(String email, Long id, CreateWorkoutSessionRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(id, "WorkoutSession");
        }
        if (req.getNotes() != null && !req.getNotes().isEmpty()) {
            workoutSession.setNotes(req.getNotes());
        }

        if (req.getEndTime() != null && !req.getEndTime().isEmpty()) {
            workoutSession.setEndTime(parseDate(req.getEndTime()));
        }
        WorkoutSession savedSession = workoutSessionRepo.save(workoutSession);
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(savedSession.getId());
        List<WorkoutExerciseResponse> workoutExerciseResponses = workoutExercises.stream()
                .map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
        return toWorkoutSessionResponse(savedSession, workoutExerciseResponses);
    }

    public WorkoutExerciseResponse createWorkoutExercise(String email, Long workoutId, CreateWorkoutExerciseReqeust req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(workoutId).orElseThrow(() -> new DataNotFoundException(workoutId, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutId, "WorkoutSession");
        }
        Exercise exercise = exerciseRepo.findById(req.getExerciseId()).orElseThrow(() -> new DataNotFoundException(req.getExerciseId(), "Exercise"));

        WorkoutExercise workoutExercise = new WorkoutExercise(workoutSession, exercise);
        WorkoutExercise savedWorkoutExercise = workoutExerciseRepo.save(workoutExercise);
        List<SetLog> setLogs = setLogRepo.findByWorkoutExerciseId(savedWorkoutExercise.getId());
        return toWorkoutExerciseResponse(savedWorkoutExercise, setLogs);
    }

    public void deleteWorkoutSession(String email, Long id) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(id, "WorkoutSession");
        }
        workoutSessionRepo.delete(workoutSession);
    }

    public List<WorkoutExerciseResponse> getWorkoutExercises(String email, Long workoutId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(workoutId).orElseThrow(() -> new DataNotFoundException(workoutId, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutId, "WorkoutSession");
        }
        List<WorkoutExercise> workoutExercises = workoutExerciseRepo.findByWorkoutSessionId(workoutId);
        return workoutExercises.stream().map(we -> toWorkoutExerciseResponse(we, setLogRepo.findByWorkoutExerciseId(we.getId()))).toList();
    }

    public void deleteWorkoutExercise(String email, Long workoutId, Long exerciseId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutSession workoutSession = workoutSessionRepo.findById(workoutId).orElseThrow(() -> new DataNotFoundException(workoutId, "WorkoutSession"));
        if (!workoutSession.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutId, "WorkoutSession");
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(exerciseId).orElseThrow(() -> new DataNotFoundException(exerciseId, "WorkoutExercise"));
        if (workoutExercise.getWorkoutSession().getId() != workoutId) {
            throw new DataNotFoundException(exerciseId, "Exercise");
        }
        workoutExerciseRepo.delete(workoutExercise);
    }

    public List<SetLogResponse> createSetLog(String email, Long workoutExerciseId, CreateSetLogRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId).orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));

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
            response.add(toSetLogResponse(setLogRepo.save(setLog)));
        }

        return response;
    }

    public SetLogResponse updateSetLog(String email, Long workoutExerciseId, Long setLogId, CreateSetLogRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId).orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));

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

    public void deleteSetLog(String email, Long workoutExerciseId, Long setLogId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutExercise workoutExercise = workoutExerciseRepo.findById(workoutExerciseId).orElseThrow(() -> new DataNotFoundException(workoutExerciseId, "WorkoutExercise"));
        if (!workoutExercise.getWorkoutSession().getUser().getEmail().equals(email)) {
            throw new DataNotFoundException(workoutExerciseId, "WorkoutExercise");
        }
        SetLog setLog = setLogRepo.findById(setLogId).orElseThrow(() -> new DataNotFoundException(setLogId, "SetLog"));
        if (setLog.getWorkoutExercise().getId() != workoutExerciseId) {
            throw new DataNotFoundException(setLogId, "SetLog");
        }
        setLogRepo.delete(setLog);
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
                exercise.getCreatedAt()
        );
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
                setLog.getCalories()
        );
    }

    private WorkoutSessionResponse toWorkoutSessionResponse(WorkoutSession workoutSession, List<WorkoutExerciseResponse> workoutExerciseResponses) {
        return new WorkoutSessionResponse(
                workoutSession.getId(),
                workoutSession.getUser().getId(),
                workoutSession.getWorkoutLocation().getId(),
                workoutSession.getStartTime(),
                workoutSession.getEndTime(),
                workoutSession.getNotes(),
                workoutExerciseResponses
        );
    }
}

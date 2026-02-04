package com.example.fitrbackend.service;

import com.example.fitrbackend.exception.DataCreationFailedException;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
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

    public WorkoutSessionService(WorkoutSessionRepository workoutSessionRepo, UserRepository userRepo,
            LocationRepository locationRepo, WorkoutExerciseRepository workoutExerciseRepo) {
        this.workoutSessionRepo = workoutSessionRepo;
        this.userRepo = userRepo;
        this.locationRepo = locationRepo;
        this.workoutExerciseRepo = workoutExerciseRepo;
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
                .map(this::toWorkoutExerciseResponse).toList();
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
                        .map(this::toWorkoutExerciseResponse).toList();
                return toWorkoutSessionResponse(ws, exerciseResponses);
            }).toList();
        }
        return workoutSessions.stream().map(ws -> {
            List<WorkoutExercise> exercises = workoutExerciseRepo.findByWorkoutSessionId(ws.getId());
            List<WorkoutExerciseResponse> exerciseResponses = exercises.stream()
                    .map(this::toWorkoutExerciseResponse).toList();
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
        List<WorkoutExerciseResponse> workoutExerciseResponses = workoutExercises.stream().map(this::toWorkoutExerciseResponse).toList();
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
                .map(this::toWorkoutExerciseResponse).toList();
        return toWorkoutSessionResponse(savedSession, workoutExerciseResponses);
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

    private WorkoutExerciseResponse toWorkoutExerciseResponse(WorkoutExercise workoutExercise) {
        return new WorkoutExerciseResponse(
                workoutExercise.getId(),
                workoutExercise.getWorkoutSession().getId(),
                workoutExercise.getExercise().getId(),
                workoutExercise.getMeasurementType());
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

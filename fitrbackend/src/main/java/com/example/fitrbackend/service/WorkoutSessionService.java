package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.CreateWorkoutSessionRequest;
import com.example.fitrbackend.dto.WorkoutSessionResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.Location;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.WorkoutSession;
import com.example.fitrbackend.repository.LocationRepository;
import com.example.fitrbackend.repository.UserRepository;
import com.example.fitrbackend.repository.WorkoutSessionRepository;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class WorkoutSessionService {

    private final WorkoutSessionRepository workoutSessionRepo;
    private final UserRepository userRepo;
    private final LocationRepository locationRepo;

    public WorkoutSessionService(WorkoutSessionRepository workoutSessionRepo, UserRepository userRepo, LocationRepository locationRepo) {
        this.workoutSessionRepo = workoutSessionRepo;
        this.userRepo = userRepo;
        this.locationRepo = locationRepo;
    }

    public WorkoutSessionResponse createWorkoutSession(String email, CreateWorkoutSessionRequest req) {

        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        Location location = locationRepo.findById(req.getLocationId()).orElseThrow(() -> new DataNotFoundException("location not found"));
        WorkoutSession workoutSession = new WorkoutSession(user, Instant.now(), null, req.getNotes(), location);
        return toWorkoutSessionResponse(workoutSessionRepo.save(workoutSession));
    }

    public List<WorkoutSessionResponse> getWorkoutSessions(String email, String fromDate, String toDate, int limit) {
        List<WorkoutSession> workoutSessions = workoutSessionRepo.findByUserEmail(email);
        if (fromDate != null && !fromDate.isEmpty()) {
            Instant fromDateInstant = Instant.parse(fromDate);
            workoutSessions = workoutSessions.stream().filter(w -> w.getStartTime().isAfter(fromDateInstant)).toList();
        }
        if (toDate != null && !toDate.isEmpty()) {
            Instant toDateInstant = Instant.parse(toDate);
            workoutSessions = workoutSessions.stream().filter(w -> w.getStartTime().isBefore(toDateInstant)).toList();
        }
        if (limit > 0) {
            return workoutSessions.stream().limit(limit).map(this::toWorkoutSessionResponse).toList();
        }
        return new ArrayList<>();
    }

    private WorkoutSessionResponse toWorkoutSessionResponse(WorkoutSession workoutSession) {
        return new WorkoutSessionResponse(
                workoutSession.getId(),
                workoutSession.getUser().getId(),
                workoutSession.getWorkoutLocation().getId(),
                workoutSession.getStartTime(),
                workoutSession.getEndTime(),
                workoutSession.getNotes()
        );
    }
}

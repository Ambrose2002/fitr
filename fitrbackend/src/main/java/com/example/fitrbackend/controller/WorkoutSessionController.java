package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateWorkoutExerciseReqeust;
import com.example.fitrbackend.dto.CreateWorkoutSessionRequest;
import com.example.fitrbackend.dto.WorkoutExerciseResponse;
import com.example.fitrbackend.dto.WorkoutSessionResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.service.WorkoutSessionService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/workouts")
public class WorkoutSessionController {

    private final WorkoutSessionService workoutSessionService;

    public WorkoutSessionController(WorkoutSessionService workoutSessionService) {
        this.workoutSessionService = workoutSessionService;
    }

    @PostMapping
    public WorkoutSessionResponse createWorkoutSession(@RequestBody CreateWorkoutSessionRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.createWorkoutSession(email, req);
    }

    @GetMapping
    public List<WorkoutSessionResponse> getWorkoutSessions(@RequestParam(name = "limit", required = false) Integer limit, @RequestParam(name = "startDate", required = false) String fromDate, @RequestParam(name = "endDate", required = false) String toDate) {
        try
        {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null) {
                throw new AuthenticationFailedException("auth not found");
            }
            String email = auth.getName();
            return workoutSessionService.getWorkoutSessions(email, fromDate, toDate, limit);
        } catch (Exception e) {
            throw new DataNotFoundException("Could not find workouts within the constraints");
        }
    }

    @GetMapping("/{id}")
    public WorkoutSessionResponse getWorkoutSession(@PathVariable Long id) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.getWorkoutSession(email, id);
    }

    @PutMapping("/{id}")
    public WorkoutSessionResponse updateWorkoutSession(@PathVariable Long id, @RequestBody CreateWorkoutSessionRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.updateWorkoutSession(email, id, req);
    }

    @DeleteMapping("/{id}")
    public void deleteWorkoutSession(@PathVariable Long id) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        workoutSessionService.deleteWorkoutSession(email, id);
    }

    @PostMapping("/{workoutId}/exercises")
    public WorkoutExerciseResponse createWorkoutExercise(@PathVariable Long workoutId, @RequestBody CreateWorkoutExerciseReqeust req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.createWorkoutExercise(email, workoutId, req);
    }

    @GetMapping("/{workoutId}/exercises")
    public List<WorkoutExerciseResponse> getWorkoutExercises(@PathVariable Long workoutId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.getWorkoutExercises(email, workoutId);
    }

    @DeleteMapping("/{workoutId}/exercises/{exerciseId}")
    public void removeWorkoutExerciseFromWorkout(@PathVariable Long workoutId, @PathVariable Long exerciseId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        workoutSessionService.deleteWorkoutExercise(email, workoutId, exerciseId);
    }
}

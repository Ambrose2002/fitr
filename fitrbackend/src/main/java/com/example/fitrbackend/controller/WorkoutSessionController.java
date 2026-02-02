package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateWorkoutSessionRequest;
import com.example.fitrbackend.dto.WorkoutSessionResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.model.WorkoutSession;
import com.example.fitrbackend.service.WorkoutSessionService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
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
    public List<WorkoutSessionResponse> getWorkoutSessions(@RequestParam(name = "limit", required = false) int limit, @RequestParam(name = "startDate", required = false) String fromDate, @RequestParam(name = "endDate", required = false) String toDate) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.getWorkoutSessions(email, fromDate, toDate, limit);
    }
}

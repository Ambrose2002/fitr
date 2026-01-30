package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateWorkoutPlanRequest;
import com.example.fitrbackend.dto.WorkoutPlanResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.service.WorkoutPlanService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/plans")
public class WorkoutPlanController {

    private final WorkoutPlanService workoutPlanService;

    public WorkoutPlanController(WorkoutPlanService workoutPlanService){
        this.workoutPlanService = workoutPlanService;
    }

    @GetMapping
    public List<WorkoutPlanResponse> getWorkoutPlans() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutPlanService.getWorkoutPlans(email);
    }

    @PostMapping
    public WorkoutPlanResponse createWorkoutPlan(@RequestBody CreateWorkoutPlanRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutPlanService.createWorkoutPlan(email, req);
    }
}

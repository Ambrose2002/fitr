package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateWorkoutPlanDayRequest;
import com.example.fitrbackend.dto.CreateWorkoutPlanRequest;
import com.example.fitrbackend.dto.PlanDayResponse;
import com.example.fitrbackend.dto.WorkoutPlanResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.service.WorkoutPlanService;
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

    @GetMapping("/{id}")
    public WorkoutPlanResponse getWorkoutPlan(@PathVariable Long id) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutPlanService.getWorkoutPlan(email, id);
    }

    @PutMapping("/{id}")
    public WorkoutPlanResponse updateWorkoutPlan(@PathVariable Long id, @RequestBody CreateWorkoutPlanRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutPlanService.updateWorkoutPlan(email, id, req);
    }

    @DeleteMapping("/{id}")
    public void deleteWorkoutPlan(@PathVariable Long id) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        workoutPlanService.deleteWorkoutPlan(email, id);
    }

    @PostMapping("/{planId}/days")
    public PlanDayResponse addDayToWorkoutPlan(@PathVariable Long planId, @RequestBody CreateWorkoutPlanDayRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutPlanService.addDayToWorkoutPlan(email, planId, req);
    }
}

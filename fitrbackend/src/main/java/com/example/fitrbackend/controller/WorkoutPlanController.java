package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.WorkoutPlanResponse;
import com.example.fitrbackend.repository.WorkoutPlanRepository;
import com.example.fitrbackend.service.WorkoutPlanService;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
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
        return null;
    }
}

package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.WorkoutPlanResponse;
import com.example.fitrbackend.model.WorkoutPlan;
import com.example.fitrbackend.repository.WorkoutPlanRepository;
import org.springframework.stereotype.Service;

@Service
public class WorkoutPlanService {

    private final WorkoutPlanRepository workoutPlanRepo;

    public WorkoutPlanService(WorkoutPlanRepository workoutPlanRepo) {
        this.workoutPlanRepo = workoutPlanRepo;
    }

    public WorkoutPlanResponse toWorkoutPlanResponse(WorkoutPlan workoutPlan) {
        return new WorkoutPlanResponse(
                workoutPlan.getId(),
                workoutPlan.getUser().getId(),
                workoutPlan.getName(),
                workoutPlan.getCreatedAt(),
                workoutPlan.isActive());
    }
}

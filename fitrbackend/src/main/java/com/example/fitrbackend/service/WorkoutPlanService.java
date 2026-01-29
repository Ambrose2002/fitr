package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.WorkoutPlanResponse;
import com.example.fitrbackend.model.WorkoutPlan;
import com.example.fitrbackend.repository.WorkoutPlanRepository;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class WorkoutPlanService {

    private final WorkoutPlanRepository workoutPlanRepo;

    public WorkoutPlanService(WorkoutPlanRepository workoutPlanRepo) {
        this.workoutPlanRepo = workoutPlanRepo;
    }


    public List<WorkoutPlanResponse> getWorkoutPlans(String email) {
        return workoutPlanRepo.findUserWorkoutPlans(email).stream().map(this::toWorkoutPlanResponse).toList();
    }


    private WorkoutPlanResponse toWorkoutPlanResponse(WorkoutPlan workoutPlan) {
        return new WorkoutPlanResponse(
                workoutPlan.getId(),
                workoutPlan.getUser().getId(),
                workoutPlan.getName(),
                workoutPlan.getCreatedAt(),
                workoutPlan.isActive());
    }
}

package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.CreateWorkoutPlanRequest;
import com.example.fitrbackend.dto.WorkoutPlanResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.WorkoutPlan;
import com.example.fitrbackend.repository.UserRepository;
import com.example.fitrbackend.repository.WorkoutPlanRepository;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;

@Service
public class WorkoutPlanService {

    private final WorkoutPlanRepository workoutPlanRepo;
    private final UserRepository userRepo;

    public WorkoutPlanService(WorkoutPlanRepository workoutPlanRepo, UserRepository userRepo) {
        this.workoutPlanRepo = workoutPlanRepo;
        this.userRepo = userRepo;
    }


    public List<WorkoutPlanResponse> getWorkoutPlans(String email) {
        return workoutPlanRepo.findUserWorkoutPlans(email).stream().map(this::toWorkoutPlanResponse).toList();
    }

    public WorkoutPlanResponse createWorkoutPlan(String email, CreateWorkoutPlanRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }

        WorkoutPlan workoutPlan = new WorkoutPlan(user, req.getName());
        return toWorkoutPlanResponse(workoutPlanRepo.save(workoutPlan));
    }

    public WorkoutPlanResponse getWorkoutPlan(String email, long id) {
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(id, "workout plan");
        }
        return toWorkoutPlanResponse(workoutPlan);
    }

    public WorkoutPlanResponse updateWorkoutPlan(String email, long id, CreateWorkoutPlanRequest req) {
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(id, "workout plan");
        }
        workoutPlan.setName(req.getName());
        return toWorkoutPlanResponse(workoutPlanRepo.save(workoutPlan));
    }

    public void deleteWorkoutPlan(String email, long id) {
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(id, "workout plan");
        }
        workoutPlanRepo.delete(workoutPlan);
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

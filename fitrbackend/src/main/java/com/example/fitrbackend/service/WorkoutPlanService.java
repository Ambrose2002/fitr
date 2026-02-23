package com.example.fitrbackend.service;

import java.util.List;
import java.util.Objects;

import org.springframework.stereotype.Service;

import com.example.fitrbackend.dto.CreateWorkoutPlanDayRequest;
import com.example.fitrbackend.dto.CreateWorkoutPlanRequest;
import com.example.fitrbackend.dto.PlanDayResponse;
import com.example.fitrbackend.dto.WorkoutPlanResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.PlanDay;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.WorkoutPlan;
import com.example.fitrbackend.repository.PlanDayRepository;
import com.example.fitrbackend.repository.UserRepository;
import com.example.fitrbackend.repository.WorkoutPlanRepository;

@Service
public class WorkoutPlanService {

    private final WorkoutPlanRepository workoutPlanRepo;
    private final UserRepository userRepo;
    private final PlanDayRepository planDayRepo;

    public WorkoutPlanService(WorkoutPlanRepository workoutPlanRepo, UserRepository userRepo,
            PlanDayRepository planDayRepo) {
        this.workoutPlanRepo = workoutPlanRepo;
        this.userRepo = userRepo;
        this.planDayRepo = planDayRepo;
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
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException(id, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(id, "workout plan");
        }
        return toWorkoutPlanResponse(workoutPlan);
    }

    public WorkoutPlanResponse updateWorkoutPlan(String email, long id, CreateWorkoutPlanRequest req) {
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException(id, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(id, "workout plan");
        }
        workoutPlan.setName(req.getName());
        if (req.getIsActive() != null) {
            workoutPlan.setActive(req.getIsActive());
        }
        return toWorkoutPlanResponse(workoutPlanRepo.save(workoutPlan));
    }

    public void deleteWorkoutPlan(String email, long id) {
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException(id, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(id, "workout plan");
        }
        workoutPlanRepo.delete(workoutPlan);
    }

    public List<PlanDayResponse> getPlanDays(String email, long planId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(planId)
                .orElseThrow(() -> new DataNotFoundException(planId, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(planId, "workout plan");
        }
        return planDayRepo.findByWorkoutPlanId(planId).stream().map(this::toPlanDayResponse).toList();
    }

    public PlanDayResponse getPlanDay(String email, long planId, long dayId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(planId)
                .orElseThrow(() -> new DataNotFoundException(planId, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(planId, "workout plan");
        }
        PlanDay planDay = planDayRepo.findById(dayId).orElseThrow(() -> new DataNotFoundException(dayId, "plan day"));
        if (!Objects.equals(planDay.getWorkoutPlan().getId(), planId)) {
            throw new DataNotFoundException(dayId, "plan day");
        }
        return toPlanDayResponse(planDay);
    }

    public PlanDayResponse addDayToWorkoutPlan(String email, long planId, CreateWorkoutPlanDayRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(planId)
                .orElseThrow(() -> new DataNotFoundException(planId, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(planId, "workout plan");
        }

        if (req.getDayNumber() <= 0 || req.getDayNumber() > 7) {
            throw new DataCreationFailedException("dayNumber must be between 1 and 7");
        }
        if (req.getName() == null || req.getName().isEmpty()) {
            throw new DataCreationFailedException("name cannot be empty");
        }
        PlanDay planDay = new PlanDay(workoutPlan, req.getDayNumber(), req.getName());
        return toPlanDayResponse(planDayRepo.save(planDay));
    }

    public PlanDayResponse updateDayInWorkoutPlan(String email, long planId, long dayId,
            CreateWorkoutPlanDayRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(planId)
                .orElseThrow(() -> new DataNotFoundException(planId, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(planId, "workout plan");
        }
        PlanDay planDay = planDayRepo.findById(dayId).orElseThrow(() -> new DataNotFoundException(dayId, "plan day"));
        if (!Objects.equals(planDay.getWorkoutPlan().getId(), planId)) {
            throw new DataNotFoundException(dayId, "plan day");
        }
        if (req.getDayNumber() >= 1 && req.getDayNumber() <= 7) {
            planDay.setDayNumber(req.getDayNumber());
        }
        if (req.getName() != null && !req.getName().isEmpty()) {
            planDay.setName(req.getName());
        }
        return toPlanDayResponse(planDayRepo.save(planDay));
    }

    public void deleteDayInWorkoutPlan(String email, long planId, long dayId) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        WorkoutPlan workoutPlan = workoutPlanRepo.findById(planId)
                .orElseThrow(() -> new DataNotFoundException(planId, "workout plan"));
        if (!Objects.equals(workoutPlan.getUser().getEmail(), email)) {
            throw new DataNotFoundException(planId, "workout plan");
        }
        PlanDay planDay = planDayRepo.findById(dayId).orElseThrow(() -> new DataNotFoundException(dayId, "plan day"));
        if (!Objects.equals(planDay.getWorkoutPlan().getId(), planId)) {
            throw new DataNotFoundException(dayId, "plan day");
        }
        planDayRepo.delete(planDay);
    }

    private WorkoutPlanResponse toWorkoutPlanResponse(WorkoutPlan workoutPlan) {
        return new WorkoutPlanResponse(
                workoutPlan.getId(),
                workoutPlan.getUser().getId(),
                workoutPlan.getName(),
                workoutPlan.getCreatedAt(),
                workoutPlan.isActive());
    }

    private PlanDayResponse toPlanDayResponse(PlanDay planDay) {
        return new PlanDayResponse(
                planDay.getId(),
                planDay.getWorkoutPlan().getId(),
                planDay.getDayNumber(),
                planDay.getName());
    }
}

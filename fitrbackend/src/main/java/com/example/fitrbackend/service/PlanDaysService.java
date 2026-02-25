package com.example.fitrbackend.service;

import java.util.List;
import java.util.Objects;

import org.springframework.stereotype.Service;

import com.example.fitrbackend.dto.CreatePlanDayExerciseRequest;
import com.example.fitrbackend.dto.PlanExerciseResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.Exercise;
import com.example.fitrbackend.model.PlanDay;
import com.example.fitrbackend.model.PlanExercise;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.ExerciseRepository;
import com.example.fitrbackend.repository.PlanDayRepository;
import com.example.fitrbackend.repository.PlanExerciseRepository;
import com.example.fitrbackend.repository.UserRepository;

@Service
public class PlanDaysService {

    private final PlanExerciseRepository planExerciseRepo;
    private final ExerciseRepository exerciseRepo;
    private final UserRepository userRepo;
    private final PlanDayRepository planDayRepo;

    public PlanDaysService(PlanExerciseRepository planExerciseRepo, UserRepository userRepo,
            PlanDayRepository planDayRepo, ExerciseRepository exerciseRepo) {
        this.exerciseRepo = exerciseRepo;
        this.planDayRepo = planDayRepo;
        this.planExerciseRepo = planExerciseRepo;
        this.userRepo = userRepo;
    }

    public List<PlanExerciseResponse> getPlanDayExercises(String email, Long dayId) {
        List<PlanExercise> planExercises = planExerciseRepo.findByPlanDayId(dayId);
        return planExercises.stream().map(this::toPlanExerciseResponse).toList();
    }

    public PlanExerciseResponse getPlanDayExercise(String email, long dayId, long exerciseId) {
        PlanExercise planExercise = planExerciseRepo.findById(exerciseId)
                .orElseThrow(() -> new DataNotFoundException(exerciseId, "plan exercise"));
        if (!Objects.equals(planExercise.getPlanDay().getId(), dayId)) {
            throw new DataNotFoundException(exerciseId, "plan exercise");
        }
        if (!Objects.equals(planExercise.getPlanDay().getWorkoutPlan().getUser().getEmail(), email)) {
            throw new DataNotFoundException(exerciseId, "plan exercise");
        }
        return toPlanExerciseResponse(planExercise);
    }

    public PlanExerciseResponse addExerciseToPlanDay(String email, long dayId, CreatePlanDayExerciseRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        PlanDay planDay = planDayRepo.findById(dayId).orElseThrow(() -> new DataNotFoundException(dayId, "plan day"));
        if (!Objects.equals(planDay.getWorkoutPlan().getUser().getEmail(), email)) {
            throw new DataNotFoundException(dayId, "plan day");
        }
        Exercise exercise = exerciseRepo.findById(req.getExerciseId())
                .orElseThrow(() -> new DataNotFoundException(req.getExerciseId(), "exercise"));
        if (!exercise.isSystemDefined() && !Objects.equals(exercise.getUser().getEmail(), email)) {
            throw new DataCreationFailedException("user does not own exercise");
        }
        float targetWeight = req.getTargetWeight() != null ? req.getTargetWeight() : 0f;
        PlanExercise planExercise = new PlanExercise(
                planDay,
                exercise,
                req.getTargetSets(),
                req.getTargetReps(),
                req.getTargetDurationSeconds(),
                req.getTargetDistance(),
                req.getTargetCalories(),
                targetWeight);
        return toPlanExerciseResponse(planExerciseRepo.save(planExercise));
    }

    public PlanExerciseResponse updatePlanDayExercise(String email, long dayId, long exerciseId,
            CreatePlanDayExerciseRequest req) {
                System.out.println("Request made");
        PlanExercise planExercise = planExerciseRepo.findById(exerciseId)
                .orElseThrow(() -> new DataNotFoundException(exerciseId, "plan exercise"));
        if (!Objects.equals(planExercise.getPlanDay().getId(), dayId)) {
            System.out.println("throwing error 0");
            throw new DataNotFoundException(exerciseId, "plan exercise");
        }
        if (!Objects.equals(planExercise.getPlanDay().getWorkoutPlan().getUser().getEmail(), email)) {
            System.out.println("throwing error 1");
            throw new DataNotFoundException(exerciseId, "plan exercise");
        }
        if (req.getTargetSets() >= 0) {
            planExercise.setTargetSets(req.getTargetSets());
        }
        if (req.getTargetReps() >= 0) {
            planExercise.setTargetReps(req.getTargetReps());
        }
        if (req.getTargetDurationSeconds() >= 0) {
            planExercise.setTargetDurationSeconds(req.getTargetDurationSeconds());
        }
        if (req.getTargetDistance() >= 0) {
            planExercise.setTargetDistance(req.getTargetDistance());
        }
        if (req.getTargetCalories() >= 0) {
            planExercise.setTargetCalories(req.getTargetCalories());
        }
        if (req.getTargetWeight() != null && req.getTargetWeight() >= 0) {
            planExercise.setTargetWeight(req.getTargetWeight());
        }
        return toPlanExerciseResponse(planExerciseRepo.save(planExercise));
    }

    public void deletePlanDayExercise(String email, long dayId, long exerciseId) {
        PlanExercise planExercise = planExerciseRepo.findById(exerciseId)
                .orElseThrow(() -> new DataNotFoundException(exerciseId, "plan exercise"));
        if (!Objects.equals(planExercise.getPlanDay().getId(), dayId)) {
            throw new DataNotFoundException(exerciseId, "plan exercise");
        }
        if (!Objects.equals(planExercise.getPlanDay().getWorkoutPlan().getUser().getEmail(), email)) {
            throw new DataNotFoundException(exerciseId, "plan exercise");
        }
        planExerciseRepo.delete(planExercise);
    }

    private PlanExerciseResponse toPlanExerciseResponse(PlanExercise planExercise) {
        return new PlanExerciseResponse(
                planExercise.getId(),
                planExercise.getPlanDay().getId(),
                planExercise.getExercise().getId(),
                planExercise.getTargetSets(),
                planExercise.getTargetReps(),
                planExercise.getTargetDurationSeconds(),
                planExercise.getTargetDistance(),
                planExercise.getTargetCalories(),
                planExercise.getTargetWeight());
    }
}

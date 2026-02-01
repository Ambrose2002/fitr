package com.example.fitrbackend.service;

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
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;

@Service
public class PlanDaysService {

    private final PlanExerciseRepository planExerciseRepo;
    private final ExerciseRepository exerciseRepo;
    private final UserRepository userRepo;
    private final PlanDayRepository planDayRepo;

    public PlanDaysService(PlanExerciseRepository planExerciseRepo, UserRepository userRepo, PlanDayRepository planDayRepo, ExerciseRepository exerciseRepo) {
        this.exerciseRepo = exerciseRepo;
        this.planDayRepo = planDayRepo;
        this.planExerciseRepo = planExerciseRepo;
        this.userRepo = userRepo;
    }

    public List<PlanExerciseResponse> getPlanDayExercises(String email, Long dayId) {
        List<PlanExercise> planExercises = planExerciseRepo.findByPlanDayId(dayId);
        return planExercises.stream().map(this::toPlanExerciseResponse).toList();
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
        Exercise exercise = exerciseRepo.findById(req.getExerciseId()).orElseThrow(() -> new DataNotFoundException(req.getExerciseId(), "exercise"));
        if (!exercise.isSystemDefined() && !Objects.equals(exercise.getUser().getEmail(), email)) {
            throw new DataCreationFailedException("user does not own exercise");
        }
        PlanExercise planExercise = new PlanExercise(
                planDay,
                exercise,
                req.getTargetSets(),
                req.getTargetReps(),
                req.getTargetDurationSeconds(),
                req.getTargetDistance(),
                req.getTargetCalories()
        );
        return toPlanExerciseResponse(planExerciseRepo.save(planExercise));
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
            planExercise.getTargetCalories()
        );
    }
}

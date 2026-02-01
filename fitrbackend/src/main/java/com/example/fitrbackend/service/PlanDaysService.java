package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.PlanExerciseResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.PlanExercise;
import com.example.fitrbackend.repository.PlanExerciseRepository;

public class PlanDaysService {

    private final PlanExerciseRepository planExerciseRepo;

    public PlanDaysService(PlanExerciseRepository planExerciseRepo) {
        this.planExerciseRepo = planExerciseRepo;
    }

    public PlanExerciseResponse getPlanExercise(Long id) {
        PlanExercise planExercise = planExerciseRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "plan exercise"));
        return toPlanExerciseResponse(planExercise);
    }

    public PlanExerciseResponse addExerciseToPlanDay() {
        return null;
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

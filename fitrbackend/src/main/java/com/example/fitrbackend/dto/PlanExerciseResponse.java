package com.example.fitrbackend.dto;

import lombok.Getter;

public class PlanExerciseResponse {

    @Getter
    private final long id;
    @Getter
    private final long plan_day_id;
    @Getter
    private final long exercise_id;
    @Getter
    private final int targetSets;
    @Getter
    private final int targetReps;
    @Getter
    private final int targetDurationSeconds;
    @Getter
    private final float targetDistance;
    @Getter
    private final float targetCalories;

    public PlanExerciseResponse(long id, long plan_day_id, long exercise_id, int targetSets, int targetReps, int targetDurationSeconds, float targetDistance, float targetCalories) {
        this.id = id;
        this.plan_day_id = plan_day_id;
        this.exercise_id = exercise_id;
        this.targetSets = targetSets;
        this.targetReps = targetReps;
        this.targetDurationSeconds = targetDurationSeconds;
        this.targetDistance = targetDistance;
        this.targetCalories = targetCalories;
    }
}

package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class CreatePlanDayExerciseRequest {
    private long exerciseId;
    private int targetSets;
    private int targetReps;
    private int targetDurationSeconds;
    private float targetDistance;
    private float targetCalories;
}

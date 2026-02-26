package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class CreatePlanDayExerciseRequest {
    private long exerciseId;
    private long targetSets;
    private long targetReps;
    private long targetDurationSeconds;
    private float targetDistance;
    private float targetCalories;
    private Float targetWeight;

    @Override
    public String toString() {
        return "CreatePlanDayExerciseRequest{" +
                "exerciseId=" + exerciseId +
                ", targetSets=" + targetSets +
                ", targetReps=" + targetReps +
                ", targetDurationSeconds=" + targetDurationSeconds +
                ", targetDistance=" + targetDistance +
                ", targetCalories=" + targetCalories +
                ", targetWeight=" + targetWeight +
                '}';
    }
}

package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class CreateSetLogRequest {
    private int sets;
    private int averageReps;
    private float averageWeight;
    private Long averageDurationSeconds;
    private float averageDistance;
    private float averageCalories;
}

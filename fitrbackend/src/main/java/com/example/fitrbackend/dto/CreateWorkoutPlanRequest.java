package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class CreateWorkoutPlanRequest {
    private String name;
    private Boolean isActive;
}

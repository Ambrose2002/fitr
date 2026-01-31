package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class CreateWorkoutPlanDayRequest {
    private int dayNumber;
    private String name;
}

package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class CreateWorkoutSessionRequest {
    private Long locationId;
    private String notes;
    private String endTime;
}

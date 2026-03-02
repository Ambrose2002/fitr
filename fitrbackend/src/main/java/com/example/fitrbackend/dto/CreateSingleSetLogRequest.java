package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class CreateSingleSetLogRequest {
    private Integer setNumber;
    private Integer reps;
    private Float weight;
    private Long durationSeconds;
    private Float distance;
    private Float calories;
}

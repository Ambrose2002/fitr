package com.example.fitrbackend.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateSingleSetLogRequest {
    private Long setNumber;
    private Long reps;
    private Float weight;
    private Long durationSeconds;
    private Float distance;
    private Float calories;
}

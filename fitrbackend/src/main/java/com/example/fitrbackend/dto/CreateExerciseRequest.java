package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.MeasurementType;
import lombok.Getter;

@Getter
public class CreateExerciseRequest {
    private String name;
    private MeasurementType measurementType;
}

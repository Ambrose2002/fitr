package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.MeasurementType;
import java.time.Instant;
import lombok.Getter;

public class ExerciseResponse {

    @Getter
    private final long id;
    @Getter
    private final String name;
    @Getter
    private final MeasurementType measurementType;
    @Getter
    private final boolean isSystemDefined;
    @Getter
    private final Instant createdAt;

    public ExerciseResponse(long id, String name, MeasurementType measurementType, boolean isSystemDefined, Instant createdAt) {
        this.id = id;
        this.name = name;
        this.measurementType = measurementType;
        this.isSystemDefined = isSystemDefined;
        this.createdAt = createdAt;
    }
}

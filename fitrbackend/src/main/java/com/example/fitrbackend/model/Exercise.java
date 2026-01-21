package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;

@Entity
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    @Getter
    @Setter
    private String name;

    @Getter
    @Setter
    private MeasurementType measurementType;

    @Getter
    @Setter
    private boolean isSystemDefined;

    @Getter
    private Instant createdAt;

    public Exercise(String name, MeasurementType measurementType, boolean isSystemDefined) {
        this.name = name;
        this.measurementType = measurementType;
        this.isSystemDefined = isSystemDefined;
        this.createdAt = Instant.now();
    }
}

package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;

/**
 * Represents an exercise in the system.
 */
@Entity
public class Exercise {

    /**
     * Unique identifier for the exercise.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    /**
     * Name of the exercise.
     */
    @Getter
    @Setter
    private String name;

    /**
     * Type of measurement for the exercise.
     */
    @Getter
    @Setter
    private MeasurementType measurementType;

    /**
     * Whether the exercise is defined by the system.
     */
    @Getter
    @Setter
    private boolean isSystemDefined;

    /**
     * Instant at which the exercise was created.
     */
    @Getter
    private Instant createdAt;

    /**
     * Creates a new exercise with the given name, measurement type, and system definition state.
     *
     * @param name            the name of the exercise
     * @param measurementType the type of measurement for the exercise
     * @param isSystemDefined whether the exercise is defined by the system
     */
    public Exercise(String name, MeasurementType measurementType, boolean isSystemDefined) {
        this.name = name;
        this.measurementType = measurementType;
        this.isSystemDefined = isSystemDefined;
        this.createdAt = Instant.now();
    }
}
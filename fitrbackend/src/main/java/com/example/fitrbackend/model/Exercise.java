package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
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
     * The owner of a user_defined exercise
     */
    @ManyToOne
    @JoinColumn(name = "user_id")
    @Getter
    private User user;

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
     * @param user owner of the exercise if the exercise is not system defined
     */
    public Exercise(String name, MeasurementType measurementType, User user) {
        this.name = name;
        this.measurementType = measurementType;
        this.user = user;
        this.isSystemDefined = user == null;
        this.createdAt = Instant.now();
    }

    /**
     * Sets the owner of the exercise.
     * If the user is null, isSystemDefined is set to true else false.
     * @param user the owner of the exercise
     */
    public void setUser(User user) {
        this.isSystemDefined = user == null;
        this.user = user;
    }
}
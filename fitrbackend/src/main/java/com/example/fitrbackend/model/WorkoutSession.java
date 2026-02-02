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
 * Represents a single workout session.
 */
@Getter
@Entity
public class WorkoutSession {

    /**
     * Unique identifier for the workout session.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    /**
     * The user that performed the workout session.
     */
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    /**
     * The location of the workout session.
     */
    @ManyToOne
    @JoinColumn(name = "workout_location_id")
    @Setter
    private Location workoutLocation;

    /**
     * The start time of the workout session.
     */
    private Instant startTime;

    /**
     * The end time of the workout session.
     */
    private Instant endTime;

    /**
     * Any notes made about the workout session.
     */
    @Setter
    private String notes;

    public WorkoutSession() {}

    /**
     * Creates a new workout session.
     *
     * @param user the user that performed the workout session
     * @param startTime the start time of the workout session
     * @param endTime the end time of the workout session
     * @param notes any notes made about the workout session
     * @param workoutLocation the location of the workout session
     */
    public WorkoutSession(User user, Instant startTime, Instant endTime, String notes, Location workoutLocation) {
        this.user = user;
        this.startTime = startTime;
        this.endTime = endTime;
        this.notes = notes;
        this.workoutLocation = workoutLocation;
    }
}
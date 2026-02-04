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
 * Represents a set log in a workout session.
 */
@Getter
@Entity
public class SetLog {

    /**
     * Unique identifier for the set log.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    /**
     * The workout session this set log belongs to.
     */
    @ManyToOne
    @JoinColumn(name = "workout_exercise_id")
    @Setter
    private WorkoutExercise workoutExercise;

    /**
     * The number of the set in the workout session.
     */
    @Setter
    private int setNumber;

    /**
     * The time at which the set was completed.
     */
    private Instant completedAt;

    /**
     * The weight used in the set.
     */
    @Setter
    private float weight;

    /**
     * The number of repetitions in the set.
     */
    @Setter
    private int reps;

    /**
     * The duration of the set in seconds.
     */
    @Setter
    private Long durationSeconds;

    /**
     * The distance covered in the set.
     */
    @Setter
    private float distance;

    /**
     * The number of calories burned in the set.
     */
    @Setter
    private float calories;

    public SetLog() {}

    /**
     * Creates a new set log with the given parameters.
     * @param workoutExercise The workout exercise this set log belongs to.
     * @param setNumber The number of the set in the workout session.
     * @param weight The weight used in the set.
     * @param reps The number of repetitions in the set.
     * @param durationSeconds The duration of the set in seconds.
     * @param distance The distance covered in the set.
     * @param calories The number of calories burned in the set.
     */
    public SetLog(WorkoutExercise workoutExercise, int setNumber, float weight, int reps, Long durationSeconds, float distance, float calories) {
        this.workoutExercise = workoutExercise;
        this.setNumber = setNumber;
        this.completedAt = Instant.now();
        this.weight = weight;
        this.reps = reps;
        this.durationSeconds = durationSeconds;
        this.distance = distance;
        this.calories = calories;
    }
}
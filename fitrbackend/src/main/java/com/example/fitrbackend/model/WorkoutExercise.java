package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.Setter;
/**
 * Represents an exercise performed in a workout session.
 */
@Getter
@Entity
public class WorkoutExercise {

    /**
     * Unique identifier for the exercise in the workout session.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    /**
     * The workout session that the exercise was performed in.
     */
    @ManyToOne
    @JoinColumn(name = "workout_session_id")
    @Setter
    private WorkoutSession workoutSession;

    /**
     * The exercise that was performed.
     */
    @ManyToOne
    @JoinColumn(name = "exercise_id")
    @Setter
    private Exercise exercise;

    /**
     * The measurement type of the exercise.
     */
    @Setter
    private MeasurementType measurementType;

    public WorkoutExercise() {}

    /**
     * Constructor for WorkoutExercise.
     *
     * @param workoutSession the workout session that the exercise was performed in
     * @param exercise the exercise that was performed
     * @param measurementType the measurement type of the exercise
     */
    public WorkoutExercise(WorkoutSession workoutSession, Exercise exercise, MeasurementType measurementType) {
        this.workoutSession = workoutSession;
        this.exercise = exercise;
        this.measurementType = measurementType;
    }
}
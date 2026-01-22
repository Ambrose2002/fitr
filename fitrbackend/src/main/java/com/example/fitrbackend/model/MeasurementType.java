package com.example.fitrbackend.model;

/**
 * Represents the type of measurement associated with a workout exercise.
 */
public enum MeasurementType {

    /**
     * The exercise is measured by the number of repetitions.
     */
    REPS,

    /**
     * The exercise is measured by the time taken to complete the exercise.
     */
    TIME,

    /**
     * The exercise is measured by the number of repetitions and the time taken to complete the exercise.
     */
    REPS_AND_TIME,

    /**
     * The exercise is measured by the time taken to complete the exercise and the weight used.
     */
    TIME_AND_WEIGHT,

    /**
     * The exercise is measured by the number of repetitions and the weight used.
     */
    REPS_AND_WEIGHT,

    /**
     * The exercise is measured by the distance travelled and the time taken to complete the exercise.
     */
    DISTANCE_AND_TIME,

    /**
     * The exercise is measured by the calories burned and the time taken to complete the exercise.
     */
    CALORIES_AND_TIME
}

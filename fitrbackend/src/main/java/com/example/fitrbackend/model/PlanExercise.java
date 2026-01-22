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
 * Represents an exercise in a workout plan.
 */
@Entity
public class PlanExercise {

    /**
     * The ID of the plan exercise.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    /**
     * The plan day that the plan exercise belongs to.
     */
    @ManyToOne
    @JoinColumn(name = "plan_day_id")
    @Getter
    @Setter
    private PlanDay planDay;

    /**
     * The exercise that the plan exercise refers to.
     */
    @ManyToOne
    @JoinColumn(name = "exercise_id")
    @Getter
    @Setter
    private Exercise exercise;

    /**
     * The target number of sets for the plan exercise.
     */
    @Getter
    @Setter
    private int targetSets;

    /**
     * The target number of reps for the plan exercise.
     */
    @Getter
    @Setter
    private int targetReps;

    /**
     * The target duration in seconds for the plan exercise.
     */
    @Getter
    @Setter
    private int targetDurationSeconds;

    /**
     * The target distance in meters for the plan exercise.
     */
    @Getter
    @Setter
    private float targetDistance;

    /**
     * The target calories for the plan exercise.
     */
    @Getter
    @Setter
    private float targetCalories;

    /**
     * Constructs a new plan exercise.
     *
     * @param planDay The plan day that the plan exercise belongs to.
     * @param exercise The exercise that the plan exercise refers to.
     * @param targetSets The target number of sets for the plan exercise.
     * @param targetReps The target number of reps for the plan exercise.
     * @param targetDurationSeconds The target duration in seconds for the plan exercise.
     * @param targetDistance The target distance in meters for the plan exercise.
     * @param targetCalories The target calories for the plan exercise.
     */
    public PlanExercise(PlanDay planDay, Exercise exercise, int targetSets, int targetReps, int targetDurationSeconds, float targetDistance, float targetCalories) {
        this.planDay = planDay;
        this.exercise = exercise;
        this.targetSets = targetSets;
        this.targetReps = targetReps;
        this.targetDurationSeconds = targetDurationSeconds;
        this.targetDistance = targetDistance;
        this.targetCalories = targetCalories;
    }
}
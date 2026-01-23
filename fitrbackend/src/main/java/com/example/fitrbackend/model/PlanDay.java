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
 * Represents a single day in a workout plan.
 */
@Entity
public class PlanDay {

    /**
     * Unique identifier for the plan day.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    /**
     * The workout plan that this day belongs to.
     */
    @ManyToOne
    @JoinColumn(name = "workout_plan_id")
    @Getter
    private WorkoutPlan workoutPlan;

    /**
     * The number of the day in the workout plan.
     */
    @Getter
    @Setter
    private int dayNumber;

    /**
     * The name of the day in the workout plan.
     */
    @Getter
    @Setter
    private String name;

    /**
     * Creates a new plan day with the given workout plan, day number, and name.
     * @param workoutPlan the workout plan that this day belongs to
     * @param dayNumber the number of the day in the workout plan
     * @param name the name of the day in the workout plan
     */
    public PlanDay(WorkoutPlan workoutPlan, int dayNumber, String name) {
        this.workoutPlan = workoutPlan;
        this.dayNumber = dayNumber;
        this.name = name;
    }

}
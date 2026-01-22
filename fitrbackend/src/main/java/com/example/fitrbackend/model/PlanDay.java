package com.example.fitrbackend.model;

import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.Setter;

public class PlanDay {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    @ManyToOne
    @JoinColumn(name = "workout_plan_id")
    @Getter
    private WorkoutPlan workoutPlan;

    @Getter
    @Setter
    private int dayNumber;

    @Getter
    @Setter
    private String name;

    public PlanDay(WorkoutPlan workoutPlan, int dayNumber, String name) {
        this.workoutPlan = workoutPlan;
        this.dayNumber = dayNumber;
        this.name = name;
    }
}

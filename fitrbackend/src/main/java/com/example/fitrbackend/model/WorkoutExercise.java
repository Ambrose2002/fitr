package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToOne;
import lombok.Getter;
import lombok.Setter;

@Entity
public class WorkoutExercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    @ManyToOne
    @JoinColumn(name = "workout_session_id")
    @Getter
    @Setter
    private WorkoutSession workoutSession;

    @ManyToOne
    @JoinColumn(name = "exercise_id")
    @Getter
    @Setter
    private Exercise exercise;

    @Getter
    @Setter
    private MeasurementType measurementType;

    public WorkoutExercise(WorkoutSession workoutSession, Exercise exercise, MeasurementType measurementType) {
        this.workoutSession = workoutSession;
        this.exercise = exercise;
        this.measurementType = measurementType;
    }

}

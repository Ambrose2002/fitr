package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.ManyToOne;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;

@Entity
public class SetLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    @ManyToOne
    @Getter
    @Setter
    private WorkoutSession workoutSession;

    @Getter
    @Setter
    private int setNumber;

    @Getter
    private Instant completedAt;

    @Getter
    @Setter
    private float weight;

    @Getter
    @Setter
    private int reps;

    @Getter
    @Setter
    private Long durationSeconds;

    @Getter
    @Setter
    private float distance;

    @Getter
    @Setter
    private  float calories;



    public SetLog(WorkoutSession workoutSession, int setNumber) {
        this.workoutSession = workoutSession;
        this.setNumber = setNumber;
        this.completedAt = Instant.now();
    }
}

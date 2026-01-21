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

@Entity
public class WorkoutSession {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    @Getter
    private User user;

    @Getter
    @Setter
    private Location workoutLocation;

    @Getter
    private Instant startTime;

    @Getter
    private Instant endTime;

    @Getter
    @Setter
    private String notes;

    public WorkoutSession(User user, Instant startTime, Instant endTime, String notes, Location workoutLocation) {
        this.user = user;
        this.startTime = startTime;
        this.endTime = endTime;
        this.notes = notes;
        this.workoutLocation = workoutLocation;
    }
}


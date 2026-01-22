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
public class WorkoutPlan {

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
    private String name;

    @Getter
    @Setter
    private Instant createdAt;

    @Getter
    @Setter
    private boolean isActive;

    public WorkoutPlan(User user, String name) {
        this.user = user;
        this.name = name;
        this.createdAt = Instant.now();
        this.isActive = true;
    }
}

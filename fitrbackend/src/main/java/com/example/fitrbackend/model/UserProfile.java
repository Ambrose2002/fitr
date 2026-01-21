package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToOne;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;

@Entity
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    @OneToOne
    @JoinColumn(name = "user_id")
    @Getter
    private final User user;

    @Getter
    @Setter
    private float height;

    @Getter
    @Setter
    private float weight;

    @Getter
    @Setter
    private ExperinceLevel experienceLevel;

    @Getter
    @Setter
    private Goal goal;

    @Getter
    @Setter
    private Unit preferredUnit;

    @Getter
    @Setter
    private Instant createdAt;

    public UserProfile(User user, float height, float weight, ExperinceLevel experienceLevel, Goal goal, Unit preferredUnit) {
        this.user = user;
        this.height = height;
        this.weight = weight;
        this.experienceLevel = experienceLevel;
        this.goal = goal;
        this.preferredUnit = preferredUnit;
        this.createdAt = Instant.now();
    }
}

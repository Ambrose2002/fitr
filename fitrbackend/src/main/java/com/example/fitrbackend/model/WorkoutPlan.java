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
/**
 * Represents a workout plan.
 */
@Entity
public class WorkoutPlan {

    /**
     * The identifier of the workout plan.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    /**
     * The user associated with the workout plan.
     */
    @ManyToOne
    @JoinColumn(name = "user_id")
    @Getter
    private User user;

    /**
     * The name of the workout plan.
     */
    @Getter
    @Setter
    private String name;

    /**
     * The time at which the workout plan was created.
     */
    @Getter
    @Setter
    private Instant createdAt;

    /**
     * Whether the workout plan is currently active.
     */
    @Getter
    @Setter
    private boolean isActive;

    /**
     * Creates a new workout plan with the specified user and name.
     *
     * @param user the user associated with the workout plan
     * @param name the name of the workout plan
     */
    public WorkoutPlan(User user, String name) {
        this.user = user;
        this.name = name;
        this.createdAt = Instant.now();
        this.isActive = true;
    }
}
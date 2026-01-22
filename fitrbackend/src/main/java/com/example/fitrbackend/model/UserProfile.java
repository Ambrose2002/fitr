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
/**
 * Represents a user's profile.
 *
 * @author Jake Byrne
 */
@Entity
public class UserProfile {

    /**
     * The ID of the user profile.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    /**
     * The associated user.
     */
    @OneToOne
    @JoinColumn(name = "user_id")
    @Getter
    private final User user;

    /**
     * The user's height in meters.
     */
    @Getter
    @Setter
    private float height;

    /**
     * The user's weight in kilograms.
     */
    @Getter
    @Setter
    private float weight;

    /**
     * The user's experience level.
     */
    @Getter
    @Setter
    private ExperienceLevel experienceLevel;

    /**
     * The user's goal.
     */
    @Getter
    @Setter
    private Goal goal;

    /**
     * The preferred unit of measurement for weight.
     */
    @Getter
    @Setter
    private Unit preferredWeightUnit;

    /**
     * The preferred unit of measurement for distance.
     */
    @Getter
    @Setter
    private Unit preferredDistanceUnit;

    /**
     * The time the user profile was created.
     */
    @Getter
    @Setter
    private Instant createdAt;

    /**
     * Constructs a new user profile.
     *
     * @param user The associated user.
     * @param height The user's height in meters.
     * @param weight The user's weight in kilograms.
     * @param experienceLevel The user's experience level.
     * @param goal The user's goal.
     * @param preferredWeightUnit The unit of measurement for the user's weight.
     * @param preferredDistanceUnit The unit of measurement for the user's preferred distance.
     */
    public UserProfile(User user, float height, float weight, ExperienceLevel experienceLevel, Goal goal, Unit preferredWeightUnit, Unit preferredDistanceUnit) {
        this.user = user;
        this.height = height;
        this.weight = weight;
        this.experienceLevel = experienceLevel;
        this.goal = goal;
        this.preferredWeightUnit = preferredWeightUnit;
        this.preferredDistanceUnit = preferredDistanceUnit;
        this.createdAt = Instant.now();
    }
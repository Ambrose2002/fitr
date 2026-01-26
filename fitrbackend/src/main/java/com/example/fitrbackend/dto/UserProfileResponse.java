package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.ExperienceLevel;
import com.example.fitrbackend.model.Gender;
import com.example.fitrbackend.model.Goal;
import com.example.fitrbackend.model.Unit;
import java.time.Instant;
import lombok.Getter;
/**
 * Represents a response to a user profile request.
 */
public class UserProfileResponse {

    /**
     * The user's ID.
     */
    @Getter
    private final long id;

    /**
     * The user's ID.
     */
    @Getter
    private final long userId;

    /**
     * The user's first name.
     */
    @Getter
    private final String firstname;

    /**
     * The user's last name.
     */
    @Getter
    private final String lastname;

    /**
     * The user's email address.
     */
    @Getter
    private final String email;

    /**
     * The user's gender.
     */
    @Getter
    private final Gender gender;

    /**
     * The user's height.
     */
    @Getter
    private final float height;

    /**
     * The user's weight.
     */
    @Getter
    private final float weight;

    /**
     * The user's experience level.
     */
    @Getter
    private final ExperienceLevel experience;

    /**
     * The user's goal.
     */
    @Getter
    private final Goal goal;

    /**
     * The user's preferred unit of weight.
     */
    @Getter
    private final Unit preferredWeightUnit;

    /**
     * The user's preferred unit of distance.
     */
    @Getter
    private final Unit preferredDistanceUnit;

    @Getter
    private final Instant createdAt;

    /**
     * Creates a new instance of the {@link UserProfileResponse} class.
     *
     * @param id The user's ID.
     * @param userId The user's ID.
     * @param firstname The user's first name.
     * @param lastname The user's last name.
     * @param email The user's email address.
     * @param gender The user's gender.
     * @param height The user's height.
     * @param weight The user's weight.
     * @param experience The user's experience level.
     * @param goal The user's goal.
     * @param preferredWeightUnit The user's preferred unit of weight.
     * @param preferredDistanceUnit The user's preferred unit of distance.
     */
    public UserProfileResponse(long id, long userId, String firstname, String lastname, String email, Gender gender, float height, float weight, ExperienceLevel experience, Goal goal, Unit preferredWeightUnit, Unit preferredDistanceUnit, Instant createdAt) {
        this.id = id;
        this.userId = userId;
        this.firstname = firstname;
        this.lastname = lastname;
        this.email = email;
        this.gender = gender;
        this.height = height;
        this.weight = weight;
        this.experience = experience;
        this.goal = goal;
        this.preferredWeightUnit = preferredWeightUnit;
        this.preferredDistanceUnit = preferredDistanceUnit;
        this.createdAt = createdAt;
    }
}
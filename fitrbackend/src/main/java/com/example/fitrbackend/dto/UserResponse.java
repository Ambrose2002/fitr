package com.example.fitrbackend.dto;

import java.time.Instant;

import lombok.Getter;

/**
 * Represents a response to a user request.
 */
@Getter
public class UserResponse {

    /**
     * The ID of the user.
     */
    private final long id;

    /**
     * The first name of the user.
     */
    private final String firstname;

    /**
     * The last name of the user.
     */
    private final String lastname;

    /**
     * The email address of the user.
     */
    private final String email;

    private final Instant createdAt;

    private final boolean isActive;

    /**
     * Whether the user has created their profile.
     */
    private final boolean isProfileCreated;

    /**
     * Creates a new UserResponse.
     *
     * @param id               The ID of the user.
     * @param firstname        The first name of the user.
     * @param lastname         The last name of the user.
     * @param email            The email address of the user.
     * @param createdAt        The timestamp when the user was created.
     * @param isActive         Whether the user account is active.
     * @param isProfileCreated Whether the user has created their profile.
     */
    public UserResponse(long id, String firstname, String lastname, String email, Instant createdAt, boolean isActive,
            boolean isProfileCreated) {
        this.id = id;
        this.firstname = firstname;
        this.lastname = lastname;
        this.email = email;
        this.createdAt = createdAt;
        this.isActive = isActive;
        this.isProfileCreated = isProfileCreated;
    }
}
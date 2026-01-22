package com.example.fitrbackend.dto;

import java.time.Instant;
import lombok.Getter;
/**
 * Represents a response to a user request.
 */
public class UserResponse {

    /**
     * The ID of the user.
     */
    @Getter
    private final long id;

    /**
     * The first name of the user.
     */
    @Getter
    private final String firstname;

    /**
     * The last name of the user.
     */
    @Getter
    private final String lastname;

    /**
     * The email address of the user.
     */
    @Getter
    private final String email;

    @Getter
    private final Instant createdAt;

    @Getter
    private final boolean isActive;

    /**
     * Creates a new UserResponse.
     *
     * @param id The ID of the user.
     * @param firstname The first name of the user.
     * @param lastname The last name of the user.
     * @param email The email address of the user.
     */
    public UserResponse(long id, String firstname, String lastname, String email, Instant createdAt, boolean isActive) {
        this.id = id;
        this.firstname = firstname;
        this.lastname = lastname;
        this.email = email;
        this.createdAt = createdAt;
        this.isActive = isActive;
    }
}
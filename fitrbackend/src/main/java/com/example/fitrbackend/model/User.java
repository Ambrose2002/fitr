package com.example.fitrbackend.model;

import jakarta.persistence.Column;
import java.time.Instant;
import lombok.Getter;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Setter;
/**
 * Represents a user in the system.
 */
@Entity
public class User {

    /**
     * Unique identifier for the user.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private Long id;

    /**
     * First name of the user.
     */
    @Getter
    @Setter
    private String firstname;

    /**
     * Last name of the user.
     */
    @Getter
    @Setter
    private String lastname;

    /**
     * Email of the user. This must be unique in the system.
     */
    @Column(name = "email", unique = true, nullable = false)
    @Getter
    @Setter
    private String email;

    /**
     * Hash of the user's password.
     */
    @Getter
    @Setter
    private String passwordHash;

    /**
     * Instant when the user was created.
     */
    @Getter
    private Instant createdAt;

    /**
     * Instant when the user last logged in.
     */
    @Getter
    @Setter
    private Instant lastLoginAt;

    /**
     * Whether the user is active or not.
     */
    @Getter
    @Setter
    private boolean isActive;

    /**
     * Creates a new user with the given details.
     * @param firstname First name of the user.
     * @param lastname Last name of the user.
     * @param email Email of the user.
     * @param passwordHash Hash of the user's password.
     */
    public User(String firstname, String lastname, String email, String passwordHash) {
        this.firstname = firstname;
        this.lastname = lastname;
        this.email = email;
        this.passwordHash = passwordHash;
        this.createdAt = Instant.now();
        this.isActive = true;
    }
}
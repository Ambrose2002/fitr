package com.example.fitrbackend.model;

import jakarta.persistence.Column;
import java.time.Instant;
import lombok.Getter;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import lombok.Setter;

@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private Long id;

    @Getter
    @Setter
    private String firstname;

    @Getter
    @Setter
    private String lastname;

    @Column(name = "email", unique = true, nullable = false)
    @Getter
    @Setter
    private String email;

    @Getter
    @Setter
    private String passwordHash;

    @Getter
    private Instant createdAt;

    @Getter
    @Setter
    private Instant lastLoginAt;

    @Getter
    @Setter
    private boolean isActive;

    public User() {

    }

    public User(String firstname, String lastname, String email, String passwordHash) {
        this.firstname = firstname;
        this.lastname = lastname;
        this.email = email;
        this.passwordHash = passwordHash;
        this.createdAt = Instant.now();
        this.isActive = true;
    }
}

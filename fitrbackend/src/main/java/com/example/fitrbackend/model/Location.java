package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.Setter;

/**
 * Represents a physical location.
 */
@Getter
@Entity
public class Location {

    /**
     * Unique identifier for this location.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    /**
     * The user associated with this location.
     */
    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;

    /**
     * The name of the location.
     */
    @Setter
    private String name;

    /**
     * The address of the location.
     */
    @Setter
    private String address;

    public Location() {}

    /**
     * Constructs a new location.
     *
     * @param name    The name of the location.
     * @param address The address of the location.
     */
    public Location(String name, String address, User user) {
        this.name = name;
        this.address = address;
        this.user = user;
    }
}

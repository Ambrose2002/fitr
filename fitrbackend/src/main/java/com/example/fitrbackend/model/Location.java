package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import lombok.Getter;
import lombok.Setter;

@Entity
public class Location {

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
    private String address;

    public Location(String name, String address) {
        this.name = name;
        this.address = address;
    }
}

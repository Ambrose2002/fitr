package com.example.fitrbackend.dto;

import lombok.Getter;

public class UserProfileResponse {

    @Getter
    private final long id;
    @Getter
    private final String firstname;
    @Getter
    private final String lastname;
    @Getter
    private final String email;
    @Getter
    private final String gender;
    @Getter
    private final String height;
    @Getter
    private final String weight;
    @Getter
    private final String experience;
    @Getter
    private final String goal;
    @Getter
    private final String preferredWeightUnit;
    @Getter
    private final String preferredDistanceUnit;

    public UserProfileResponse(long id, String firstname, String lastname, String email, String gender, String height, String weight, String experience, String goal, String preferredWeightUnit, String preferredDistanceUnit) {
        this.id = id;
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
    }
}

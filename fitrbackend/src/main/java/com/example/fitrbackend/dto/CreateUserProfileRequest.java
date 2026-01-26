package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.ExperienceLevel;
import com.example.fitrbackend.model.Gender;
import com.example.fitrbackend.model.Goal;
import com.example.fitrbackend.model.Unit;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateUserProfileRequest {

    @JsonProperty("gender")
    private Gender gender;
    @JsonProperty("height")
    private float height;
    @JsonProperty("weight")
    private float weight;
    @JsonProperty("experienceLevel")
    private ExperienceLevel experienceLevel;
    @JsonProperty("goal")
    private Goal goal;
    @JsonProperty("preferredWeightUnit")
    private Unit preferredWeightUnit;
    @JsonProperty("preferredDistanceUnit")
    private Unit preferredDistanceUnit;
}

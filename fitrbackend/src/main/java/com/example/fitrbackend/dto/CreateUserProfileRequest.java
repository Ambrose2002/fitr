package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.ExperienceLevel;
import com.example.fitrbackend.model.Gender;
import com.example.fitrbackend.model.Goal;
import com.example.fitrbackend.model.Unit;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateUserProfileRequest {
    private Gender gender;
    private float height;
    private float weight;
    private ExperienceLevel experienceLevel;
    private Goal goal;
    private Unit preferredWeightUnit;
    private Unit preferredDistanceUnit;
}

package com.example.fitrbackend.dto;

import com.fasterxml.jackson.annotation.JsonAlias;
import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;

@Getter
public class CreateWorkoutPlanDayRequest {
    @JsonProperty("day_number")
    @JsonAlias("dayNumber")
    private int dayNumber;

    @JsonProperty("name")
    private String name;
}

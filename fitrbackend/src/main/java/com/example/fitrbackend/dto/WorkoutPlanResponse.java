package com.example.fitrbackend.dto;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class WorkoutPlanResponse {

    private final long id;
    private final long user_id;
    private final String name;
    private final Instant createdAt;
    private final boolean isActive;
}

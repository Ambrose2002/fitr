package com.example.fitrbackend.dto;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
public class WorkoutPlanResponse {

    private final long id;
    private final long user_id;
    private final String name;
    private final Instant createdAt;
    private final boolean isActive;

    public WorkoutPlanResponse(long id, long user_id, String name, Instant createdAt, boolean isActive) {
        this.id = id;
        this.user_id = user_id;
        this.name = name;
        this.createdAt = createdAt;
        this.isActive = isActive;
    }
}

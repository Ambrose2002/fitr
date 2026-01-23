package com.example.fitrbackend.dto;

import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class WorkoutSessionResponse {

    private final long id;
    private final long user_id;
    private final long workout_location_id;
    private final Instant startTime;
    private final Instant endTime;
    private final Instant completedAt;
    private final String notes;
}

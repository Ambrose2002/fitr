package com.example.fitrbackend.dto;

import java.time.Instant;
import lombok.Getter;

public class SetLogResponse {

    @Getter
    private final long id;
    @Getter
    private final long workout_session_id;
    @Getter
    private final int setNumber;
    @Getter
    private final Instant completedAt;
    @Getter
    private final float weight;
    @Getter
    private final int reps;
    @Getter
    private final Long durationSeconds;
    @Getter
    private final float distance;
    @Getter
    private final float calories;

    public SetLogResponse(long id, long workout_session_id, int setNumber, Instant completedAt, float weight, int reps, Long durantionSeconds, float distance, float calories) {
        this.id = id;
        this.workout_session_id = workout_session_id;
        this.setNumber = setNumber;
        this.completedAt = completedAt;
        this.weight = weight;
        this.reps = reps;
        this.durationSeconds = durantionSeconds;
        this.distance = distance;
        this.calories = calories;
    }
}

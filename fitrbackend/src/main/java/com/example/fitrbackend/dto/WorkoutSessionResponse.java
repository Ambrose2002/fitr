package com.example.fitrbackend.dto;

import java.time.Instant;
import java.util.List;
import lombok.Getter;

@Getter
public class WorkoutSessionResponse {

    private final long id;
    private final long user_id;
    private final long workout_location_id;
    private final Instant startTime;
    private final Instant endTime;
    private final String notes;
    private final List<WorkoutExerciseResponse> exercises;

    public WorkoutSessionResponse(long id, long user_id, long workout_location_id, Instant startTime, Instant endTime, String notes, List<WorkoutExerciseResponse> exercises) {
        this.id = id;
        this.user_id = user_id;
        this.workout_location_id = workout_location_id;
        this.startTime = startTime;
        this.endTime = endTime;
        this.notes = notes;
        this.exercises = exercises;
    }
}

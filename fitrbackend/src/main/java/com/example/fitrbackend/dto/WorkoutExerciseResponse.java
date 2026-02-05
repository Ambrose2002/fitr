package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.MeasurementType;
import java.util.List;
import lombok.Getter;

@Getter
public class WorkoutExerciseResponse {

    private final long id;
    private final long workout_session_id;
    private final ExerciseResponse exercise;
    private final List<SetLogResponse> setLogs;

    public WorkoutExerciseResponse(long id, long workout_session_id, ExerciseResponse exercise, List<SetLogResponse> setLogs) {
        this.setLogs = setLogs;
        this.id = id;
        this.workout_session_id = workout_session_id;
        this.exercise = exercise;
    }
}

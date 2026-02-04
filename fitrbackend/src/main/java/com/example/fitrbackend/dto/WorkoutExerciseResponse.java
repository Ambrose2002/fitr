package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.MeasurementType;
import java.util.List;
import lombok.Getter;

public class WorkoutExerciseResponse {

    @Getter
    private final long id;
    @Getter
    private final long workout_session_id;
    @Getter
    private final long exercise_id;
    @Getter
    private final MeasurementType measurementType;

    @Getter
    private final List<SetLogResponse> setLogs;

    public WorkoutExerciseResponse(long id, long workout_session_id, long exercise_id, MeasurementType measurementType, List<SetLogResponse> setLogs) {
        this.setLogs = setLogs;
        this.id = id;
        this.workout_session_id = workout_session_id;
        this.exercise_id = exercise_id;
        this.measurementType = measurementType;
    }
}

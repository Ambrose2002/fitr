package com.example.fitrbackend.controller;

import com.example.fitrbackend.service.WorkoutSessionService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/workout-exercises/{workoutExerciseId}/sets")
public class SetLogController {

    private final WorkoutSessionService workoutSessionService;

    public SetLogController(WorkoutSessionService workoutSessionService) {
        this.workoutSessionService = workoutSessionService;
    }
}

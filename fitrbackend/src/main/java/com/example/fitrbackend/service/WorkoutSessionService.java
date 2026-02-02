package com.example.fitrbackend.service;

import com.example.fitrbackend.repository.WorkoutSessionRepository;
import org.springframework.stereotype.Service;

@Service
public class WorkoutSessionService {

    private final WorkoutSessionRepository workoutSessionRepo;

    public WorkoutSessionService(WorkoutSessionRepository workoutSessionRepo) {
        this.workoutSessionRepo = workoutSessionRepo;
    }

}

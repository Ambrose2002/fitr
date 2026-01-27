package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.ExerciseResponse;
import com.example.fitrbackend.model.Exercise;
import com.example.fitrbackend.repository.ExerciseRepository;
import com.example.fitrbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class ExerciseService {

    private final ExerciseRepository exerciseRepo;
    private final UserRepository userRepo;

    public ExerciseService(ExerciseRepository exerciseRepo, UserRepository userRepo) {
        this.exerciseRepo = exerciseRepo;
        this.userRepo = userRepo;
    }

    private ExerciseResponse toExerciseResponse (Exercise exercise) {
        return new ExerciseResponse(
            exercise.getId(),
            exercise.getName(),
            exercise.getMeasurementType(),
            exercise.isSystemDefined(),
            exercise.getCreatedAt()
        );
    }
}

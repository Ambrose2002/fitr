package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.CreateExerciseRequest;
import com.example.fitrbackend.dto.ExerciseResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.Exercise;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.ExerciseRepository;
import com.example.fitrbackend.repository.UserRepository;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;

@Service
public class ExerciseService {

    private final ExerciseRepository exerciseRepo;
    private final UserRepository userRepo;

    public ExerciseService(ExerciseRepository exerciseRepo, UserRepository userRepo) {
        this.exerciseRepo = exerciseRepo;
        this.userRepo = userRepo;
    }

    public ExerciseResponse getExercise(Long id) {
        Exercise exercise = exerciseRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "exercise"));
        return toExerciseResponse(exercise);
    }

    public List<ExerciseResponse> getAllSystemDefinedExercises() {
        return exerciseRepo.findAllSystemDefinedExercises().stream().map(this::toExerciseResponse).toList();
    }

    public List<ExerciseResponse> getAllExercisesByUser(String email) {
        return exerciseRepo.findExerciseByUserEmail(email).stream().map(this::toExerciseResponse).toList();
    }

    public ExerciseResponse createExercise(String email, CreateExerciseRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }

        if (req.getName() == null || req.getMeasurementType() == null) {
            throw new DataCreationFailedException("name or measurementType missing");
        }
        Exercise exercise = new Exercise(req.getName(), req.getMeasurementType(), user);
        return toExerciseResponse(exerciseRepo.save(exercise));
    }

    public ExerciseResponse createExercise(CreateExerciseRequest req) {
        if (req.getName() == null || req.getMeasurementType() == null) {
            throw new DataCreationFailedException("name or measurementType missing");
        }
        Exercise exercise = new Exercise(req.getName(), req.getMeasurementType(), null);
        return toExerciseResponse(exerciseRepo.save(exercise));
    }

    public ExerciseResponse updateExercise(String email, CreateExerciseRequest req, Long exerciseId) {
        Exercise exercise = exerciseRepo.findById(exerciseId).orElseThrow(() -> new DataNotFoundException(exerciseId, "exercise"));

        if (!Objects.equals(exercise.getUser().getEmail(), email)) {
            throw new DataCreationFailedException("user does not own exercise");
        }

        if (req.getName() != null && !req.getName().isEmpty()) {
            exercise.setName(req.getName());
        }

        if (req.getMeasurementType() != null) {
            exercise.setMeasurementType(req.getMeasurementType());
        }

        return toExerciseResponse(exerciseRepo.save(exercise));
    }

    public ExerciseResponse updateExercise(CreateExerciseRequest req, Long exerciseId) {
        Exercise exercise = exerciseRepo.findById(exerciseId).orElseThrow(() -> new DataNotFoundException(exerciseId, "exercise"));

        if (req.getName() != null && !req.getName().isEmpty()) {
            exercise.setName(req.getName());
        }

        if (req.getMeasurementType() != null) {
            exercise.setMeasurementType(req.getMeasurementType());
        }

        return toExerciseResponse(exerciseRepo.save(exercise));
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

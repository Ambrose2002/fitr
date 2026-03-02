package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.WorkoutExercise;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface WorkoutExerciseRepository extends JpaRepository<WorkoutExercise, Long> {

    @Query("SELECT we FROM WorkoutExercise we WHERE we.workoutSession.id = ?1")
    List<WorkoutExercise> findByWorkoutSessionId(Long workoutSessionId);

    @Query("SELECT we FROM WorkoutExercise we WHERE we.workoutSession.id = ?1 AND we.exercise.id = ?2 ORDER BY we.id ASC")
    List<WorkoutExercise> findByWorkoutSessionIdAndExerciseId(Long workoutSessionId, Long exerciseId);

    void deleteByWorkoutSessionId(Long workoutSessionId);
}

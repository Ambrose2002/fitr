package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.WorkoutExercise;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WorkoutExerciseRepository extends JpaRepository<WorkoutExercise, Long> {

}

package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.Exercise;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ExerciseRepository extends JpaRepository<Exercise, Long> {

}

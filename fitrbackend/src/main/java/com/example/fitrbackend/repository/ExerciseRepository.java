package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.Exercise;
import com.example.fitrbackend.model.User;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface ExerciseRepository extends JpaRepository<Exercise, Long> {

    @Query("SELECT e FROM Exercise e WHERE e.user.email = ?1")
    List<Exercise> findExerciseByUserEmail(String email);

    @Query("SELECT e FROM Exercise e WHERE e.isSystemDefined = true")
    List<Exercise> findAllSystemDefinedExercises();

    @Query("SELECT e FROM Exercise e WHERE e.user.email = ?1 OR e.isSystemDefined = true")
    List<Exercise> findByUserOrSystemDefined(String email);
}

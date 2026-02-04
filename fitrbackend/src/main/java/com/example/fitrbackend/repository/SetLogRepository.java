package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.SetLog;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface SetLogRepository extends JpaRepository<SetLog, Long> {
    @Query("SELECT s FROM SetLog s WHERE s.workoutExercise.id = ?1")
    List<SetLog> findByWorkoutExerciseId(Long id);
}

package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.PlanExercise;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface PlanExerciseRepository extends JpaRepository<PlanExercise, Long> {

    @Query("SELECT p FROM PlanExercise p WHERE p.planDay.id = ?1")
    List<PlanExercise> findByPlanDayId(Long planDayId);
}

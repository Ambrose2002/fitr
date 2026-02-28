package com.example.fitrbackend.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.example.fitrbackend.model.PlanExercise;

public interface PlanExerciseRepository extends JpaRepository<PlanExercise, Long> {

    @Query("SELECT p FROM PlanExercise p WHERE p.planDay.id = ?1")
    List<PlanExercise> findByPlanDayId(Long planDayId);

    boolean existsByPlanDay_IdAndExercise_Id(Long planDayId, Long exerciseId);

    Optional<PlanExercise> findByPlanDayIdAndExerciseId(Long planDayId, Long exerciseId);
}

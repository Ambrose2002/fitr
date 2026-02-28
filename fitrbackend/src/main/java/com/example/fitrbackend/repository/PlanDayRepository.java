package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.PlanDay;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface PlanDayRepository extends JpaRepository<PlanDay, Long> {

    @Query("SELECT p FROM PlanDay p WHERE p.workoutPlan.id = ?1")
    List<PlanDay> findByWorkoutPlanId(Long id);

    boolean existsByWorkoutPlan_IdAndDayNumber(Long workoutPlanId, int dayNumber);

    boolean existsByWorkoutPlan_IdAndDayNumberAndIdNot(Long workoutPlanId, int dayNumber, Long id);
}

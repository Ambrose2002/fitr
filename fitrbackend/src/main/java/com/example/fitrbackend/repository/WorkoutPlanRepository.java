package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.WorkoutPlan;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface WorkoutPlanRepository extends JpaRepository<WorkoutPlan, Long> {

    @Query("SELECT wp FROM WorkoutPlan wp WHERE wp.user.email = ?1")
    public List<WorkoutPlan> findUserWorkoutPlans(String email);
}

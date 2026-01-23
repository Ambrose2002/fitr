package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.WorkoutPlan;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WorkoutPlanRepository extends JpaRepository<WorkoutPlan, Long> {

}

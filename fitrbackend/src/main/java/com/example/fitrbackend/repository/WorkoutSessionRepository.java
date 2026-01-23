package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.WorkoutSession;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {

}

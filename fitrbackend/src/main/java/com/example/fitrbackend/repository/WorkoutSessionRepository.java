package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.WorkoutSession;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {

    @Query("SELECT w FROM WorkoutSession w WHERE w.user.email = ?1")
    List<WorkoutSession> findByUserEmail(String email);
}

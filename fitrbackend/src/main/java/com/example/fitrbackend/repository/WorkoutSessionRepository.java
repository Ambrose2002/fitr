package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.WorkoutSession;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;

public interface WorkoutSessionRepository extends JpaRepository<WorkoutSession, Long> {

    @Query("SELECT w FROM WorkoutSession w WHERE w.user.email = ?1")
    List<WorkoutSession> findByUserEmail(String email);

    @Query("SELECT w FROM WorkoutSession w WHERE w.user.email = ?1 AND w.endTime IS NULL ORDER BY w.startTime DESC")
    List<WorkoutSession> findActiveByUserEmail(String email);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE WorkoutSession ws SET ws.workoutLocation = null WHERE ws.user.id = ?1 AND ws.workoutLocation.id = ?2")
    int clearWorkoutLocationForUser(Long userId, Long locationId);
}

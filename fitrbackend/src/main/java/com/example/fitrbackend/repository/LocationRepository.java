package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.Location;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface LocationRepository extends JpaRepository<Location, Long> {

    @Query("SELECT l FROM Location l WHERE l.user.id = ?1")
    List<Location> findByUserId(Long userId);
}

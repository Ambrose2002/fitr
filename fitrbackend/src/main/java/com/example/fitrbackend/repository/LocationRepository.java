package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.Location;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LocationRepository extends JpaRepository<Location, Long> {

}

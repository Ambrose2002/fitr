package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.LocationResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.Location;
import com.example.fitrbackend.repository.LocationRepository;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class LocationService {

    private final LocationRepository repo;

    public LocationService(LocationRepository repo) {
        this.repo = repo;
    }

    public LocationResponse getLocation(Long id) {
        Location location = repo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "location"));
        return toLocationResponse(location);
    }

    public List<LocationResponse> getLocations(Long userId) {
        return repo.findByUserId(userId).stream().map(this::toLocationResponse).toList();
    }

    private LocationResponse toLocationResponse(Location location) {
        return new LocationResponse(
                location.getId(),
                location.getUser().getId(),
                location.getName(),
                location.getAddress()
        );
    }
}

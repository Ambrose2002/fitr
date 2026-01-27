package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.CreateLocationRequest;
import com.example.fitrbackend.dto.LocationResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.Location;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.LocationRepository;
import com.example.fitrbackend.repository.UserRepository;
import java.util.List;
import java.util.Objects;
import org.springframework.stereotype.Service;

@Service
public class LocationService {

    private final LocationRepository locationRepo;
    private final UserRepository userRepo;

    public LocationService(LocationRepository locationRepo, UserRepository userRepo) {
        this.locationRepo = locationRepo;
        this.userRepo = userRepo;
    }

    public LocationResponse getLocation(Long id) {
        Location location = locationRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "location"));
        return toLocationResponse(location);
    }

    public List<LocationResponse> getLocations(Long userId) {
        return locationRepo.findByUserId(userId).stream().map(this::toLocationResponse).toList();
    }

    public LocationResponse createLocation(CreateLocationRequest req, String email) {
        User user = userRepo.findByEmail(email);
        Location location = new Location(req.getName(), req.getAddress(), user);
        Location savedLocation = locationRepo.save(location);
        return toLocationResponse(savedLocation);
    }

    public LocationResponse updateLocation(CreateLocationRequest req, Long id, String userEmail) {

        User user = userRepo.findByEmail(userEmail);
        Location location = locationRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException(id, "location"));
        if (Objects.equals(location.getUser().getId(), user.getId())) {
            location.setName(req.getName());
            location.setAddress(req.getAddress());
            return toLocationResponse(locationRepo.save(location));
        } else {
            throw new DataNotFoundException(id, "location");
        }

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

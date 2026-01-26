package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.LocationResponse;
import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.service.LocationService;
import com.example.fitrbackend.service.UserService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/locations")
public class LocationController {

    private final UserService userService;
    private final LocationService locationService;

    public LocationController(UserService userService, LocationService locationService) {
        this.userService = userService;
        this.locationService = locationService;
    }

    @GetMapping
    public List<LocationResponse> getLocations() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();

        UserResponse userResponse = userService.getUser(email);
        return locationService.getLocations(userResponse.getId());
    }

}

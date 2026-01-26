package com.example.fitrbackend.controller;

import com.example.fitrbackend.service.LocationService;
import com.example.fitrbackend.service.UserService;
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



}

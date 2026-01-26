package com.example.fitrbackend.controller;

import com.example.fitrbackend.service.UserService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/locations")
public class LocationController {

    private final UserService userService;

    public LocationController(UserService userService) {
        this.userService = userService;
    }

}

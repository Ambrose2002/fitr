package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.service.UserService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("api/me")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public UserResponse getMe() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        assert auth != null;
        String email = auth.getName();

        UserResponse userResponse = userService.getUser(email);
        if (userResponse == null) {
            throw new DataNotFoundException(email);
        }
        return userResponse;
    }
}

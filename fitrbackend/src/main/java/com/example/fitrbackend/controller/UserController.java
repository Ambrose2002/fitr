package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateUserProfileRequest;
import com.example.fitrbackend.dto.UpdateUserRequest;
import com.example.fitrbackend.dto.UserProfileResponse;
import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.service.UserProfileService;
import com.example.fitrbackend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("api/me")
public class UserController {

    private final UserService userService;
    private final UserProfileService userProfileService;

    public UserController(UserService userService, UserProfileService userProfileService) {
        this.userService = userService;
        this.userProfileService = userProfileService;
    }

    @GetMapping
    public UserResponse getMe() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();

        UserResponse userResponse = userService.getUser(email);
        if (userResponse == null) {
            throw new DataNotFoundException(email);
        }
        return userResponse;
    }

    @PostMapping
    public UserResponse updateMe( @Valid @RequestBody UpdateUserRequest req) {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return userService.updateUser(email, req);
    }

    @GetMapping("/profile")
    public UserProfileResponse getProfile() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();

        UserResponse userResponse = userService.getUser(email);
        Long id = userResponse.getId();
        return userProfileService.getUserProfile(id);

    }

    @PostMapping("/profile")
    public UserProfileResponse setUserProfile(@RequestBody CreateUserProfileRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();

        UserResponse userResponse = userService.getUser(email);

        return userProfileService.createUserProfile(req, userResponse.getId());
    }
}

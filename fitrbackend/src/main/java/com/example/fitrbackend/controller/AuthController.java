package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.LoginRequest;
import com.example.fitrbackend.dto.LoginResponse;
import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.service.AuthService;
import com.example.fitrbackend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    private final UserService userService;
    private final AuthService authService;

    public AuthController(UserService service, AuthService authService) {
        this.userService = service;
        this.authService = authService;
    }

    @PostMapping("/login")
    public LoginResponse login( @Valid @RequestBody LoginRequest req) {
        String email = req.getEmail();
        String password = req.getPassword();

        UserResponse user = userService.getUser(email);

        if (user ==  null) {
            throw new AuthenticationFailedException("Invalid email or password");
        }
        if (!authService.validateUser(email, password)) {
            throw new AuthenticationFailedException("Invalid email or password");
        }
        return new LoginResponse(authService.generateToken(email));
    }
}

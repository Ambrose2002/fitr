package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.LoginRequest;
import com.example.fitrbackend.dto.LoginResponse;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/auth")
public class AuthController {

    @PostMapping("/login")
    public LoginResponse login( @RequestBody LoginRequest req) {
        String email = req.getEmail();
        String password = req.getPassword();
        return null;
    }
}

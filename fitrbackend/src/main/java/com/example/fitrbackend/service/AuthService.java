package com.example.fitrbackend.service;

import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.UserRepository;
import com.example.fitrbackend.security.JwtUtil;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class AuthService {

    private final UserRepository repo;

    private final PasswordEncoder passwordEncoder;

    public AuthService(UserRepository repo, PasswordEncoder passwordEncoder) {
        this.repo = repo;
        this.passwordEncoder = passwordEncoder;
    }

    public boolean validateUser(String email, String password) {
        User user = repo.findByEmail(email);

        if (user == null) {
            return false;
        }
        return passwordEncoder.matches(password, user.getPasswordHash());
    }

    public String generateToken(String email) {
        return JwtUtil.generateToken(email);
    }
}

package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.UserRepository;
import java.time.Instant;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository repo;

    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository repo, PasswordEncoder passwordEncoder) {
        this.repo = repo;
        this.passwordEncoder = passwordEncoder;
    }

    public UserResponse createUser(String email, String password, String firstName, String lastName) {
        String passwordHash = passwordEncoder.encode(password);
        User user = new User(firstName, lastName, email, passwordHash);
        return toResponse(repo.save(user));
    }

    public UserResponse getUser(String email) {
        User user = repo.findByEmail(email);
        if (user == null) {
            return null;
        }
        return toResponse(user);
    }

    public void updateUserLastLogin(Long id) {
        User user = repo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "user"));
        user.setLastLoginAt(Instant.now());
        repo.save(user);
    }

    private UserResponse toResponse(User user) {
        return new UserResponse(
                user.getId(),
                user.getFirstname(),
                user.getLastname(),
                user.getEmail(),
                user.getCreatedAt(),
                user.isActive());
    }
}

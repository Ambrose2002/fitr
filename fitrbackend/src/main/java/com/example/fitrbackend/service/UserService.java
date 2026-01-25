package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.UserRepository;
import java.time.Instant;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository repo;

    public UserService(UserRepository repo) { this.repo = repo;}

    public UserResponse getUser(String email) {
        try {
            return toResponse(repo.findByEmail(email));
        } catch (Exception e) {
            return null;
        }

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
                user.isActive()
        );
    }
}

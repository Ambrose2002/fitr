package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    private final UserRepository repo;

    public UserService(UserRepository repo) { this.repo = repo;}

    public User getUser(String email) {
        try {
            return repo.findByEmail(email);
        } catch (Exception e) {
            return null;
        }

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

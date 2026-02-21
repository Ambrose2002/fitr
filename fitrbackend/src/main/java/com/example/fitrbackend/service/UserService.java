package com.example.fitrbackend.service;

import java.time.Instant;
import java.util.Objects;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import com.example.fitrbackend.dto.UpdateUserRequest;
import com.example.fitrbackend.dto.UserResponse;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.UserProfileRepository;
import com.example.fitrbackend.repository.UserRepository;

@Service
public class UserService {

    private final UserRepository repo;

    private final UserProfileRepository userProfileRepository;

    private final PasswordEncoder passwordEncoder;

    public UserService(UserRepository repo, UserProfileRepository userProfileRepository,
            PasswordEncoder passwordEncoder) {
        this.repo = repo;
        this.userProfileRepository = userProfileRepository;
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

    public UserResponse getUser(Long id) {
        User user = repo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "user"));

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

    public UserResponse updateUser(String email, UpdateUserRequest req) {
        User user = repo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException(email);
        }
        String firstName = req.getFirstName();
        System.out.println(firstName);
        if (!Objects.equals(firstName, "") && firstName != null) {
            user.setFirstname(firstName);
        }

        String lastName = req.getLastName();
        if (!Objects.equals(lastName, "") && lastName != null) {
            user.setLastname(lastName);
        }

        return toResponse(repo.save(user));
    }

    private UserResponse toResponse(User user) {
        boolean hasProfile = userProfileRepository.findByUser(user) != null;
        return new UserResponse(
                user.getId(),
                user.getFirstname(),
                user.getLastname(),
                user.getEmail(),
                user.getCreatedAt(),
                user.isActive(),
                hasProfile);
    }
}

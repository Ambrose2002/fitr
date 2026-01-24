package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

    User findByEmail(String email);
}

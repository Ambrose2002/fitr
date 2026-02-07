package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.BodyMetricResponse;
import com.example.fitrbackend.dto.CreateBodyMetricRequest;
import com.example.fitrbackend.model.BodyMetric;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.BodyMetricRepository;
import com.example.fitrbackend.repository.UserRepository;
import org.springframework.stereotype.Service;

@Service
public class BodyMetricService {

    private final BodyMetricRepository bodyMetricRepo;
    private final UserRepository userRepo;

    public BodyMetricService(BodyMetricRepository bodyMetricRepo, UserRepository userRepo) {
        this.userRepo = userRepo;
        this.bodyMetricRepo = bodyMetricRepo;
    }

    public BodyMetricResponse createBodyMetric(String email, CreateBodyMetricRequest req) {
        User user = userRepo.findByEmail(email);
        BodyMetric bodyMetric = new BodyMetric(user, req.getMetricType(), req.getValue());
        bodyMetricRepo.save(bodyMetric);
        return toBodyMetricResponse(bodyMetric);
    }

    private BodyMetricResponse toBodyMetricResponse(BodyMetric bodyMetric) {
        return new BodyMetricResponse(
                bodyMetric.getId(),
                bodyMetric.getUser().getId(),
                bodyMetric.getMetricType(),
                bodyMetric.getValue(),
                bodyMetric.getRecordedAt(),
                bodyMetric.getUpdatedAt()
        );
    }
}

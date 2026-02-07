package com.example.fitrbackend.service;

import com.example.fitrbackend.repository.BodyMetricRepository;
import org.springframework.stereotype.Service;

@Service
public class BodyMetricService {

    private final BodyMetricRepository bodyMetricRepo;

    public BodyMetricService(BodyMetricRepository bodyMetricRepo) {
        this.bodyMetricRepo = bodyMetricRepo;
    }
}

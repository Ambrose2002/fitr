package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.BodyMetricResponse;
import com.example.fitrbackend.dto.CreateBodyMetricRequest;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.service.BodyMetricService;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/body-metrics")
public class BodyMetricController {

    private final BodyMetricService bodyMetricService;

    public BodyMetricController(BodyMetricService bodyMetricService) {
        this.bodyMetricService = bodyMetricService;
    }

    @PostMapping
    public BodyMetricResponse createBodyMetric(@RequestBody CreateBodyMetricRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return bodyMetricService.createBodyMetric(email, req);
    }
}

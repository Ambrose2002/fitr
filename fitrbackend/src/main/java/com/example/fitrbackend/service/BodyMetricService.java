package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.BodyMetricResponse;
import com.example.fitrbackend.dto.CreateBodyMetricRequest;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.BodyMetric;
import com.example.fitrbackend.model.MetricType;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.BodyMetricRepository;
import com.example.fitrbackend.repository.UserRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.List;
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
        if (user == null) {
            throw new DataNotFoundException("user not found: " + email);
        }
        BodyMetric bodyMetric = new BodyMetric(user, req.getMetricType(), req.getValue());
        bodyMetricRepo.save(bodyMetric);
        return toBodyMetricResponse(bodyMetric);
    }

    public List<BodyMetricResponse> getBodyMetrics(
            String email,
            MetricType metricType,
            String fromDate,
            String toDate,
            Integer limit) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException("user not found: " + email);
        }

        List<BodyMetric> bodyMetrics;
        if (metricType == null) {
            bodyMetrics = bodyMetricRepo.findByUser(user);
        } else {
            bodyMetrics = bodyMetricRepo.findByUserAndMetricType(user, metricType);
        }

        if (fromDate != null && !fromDate.isEmpty()) {
            Instant fromDateInstant = parseDate(fromDate);
            bodyMetrics = bodyMetrics.stream().filter(b -> b.getRecordedAt().isAfter(fromDateInstant)).toList();
        }
        if (toDate != null && !toDate.isEmpty()) {
            Instant toDateInstant = parseDate(toDate);
            bodyMetrics = bodyMetrics.stream().filter(b -> b.getRecordedAt().isBefore(toDateInstant)).toList();
        }
        if (limit != null && limit > 0) {
            return bodyMetrics.stream().limit(limit).map(this::toBodyMetricResponse).toList();
        }
        return bodyMetrics.stream().map(this::toBodyMetricResponse).toList();
    }

    private Instant parseDate(String dateStr) {
        try {
            // Try parsing as ISO 8601 instant first
            return Instant.parse(dateStr);
        } catch (Exception e) {
            // Fall back to parsing as date only (e.g., 2026-01-01)
            try {
                return LocalDate.parse(dateStr).atStartOfDay().toInstant(ZoneOffset.UTC);
            } catch (Exception ex) {
                throw new DataCreationFailedException("Invalid date format");
            }
        }
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

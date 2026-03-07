package com.example.fitrbackend.service;

import com.example.fitrbackend.dto.BodyMetricResponse;
import com.example.fitrbackend.dto.CreateBodyMetricRequest;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.BodyMetric;
import com.example.fitrbackend.model.MetricType;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.UserProfile;
import com.example.fitrbackend.repository.BodyMetricRepository;
import com.example.fitrbackend.repository.UserProfileRepository;
import com.example.fitrbackend.repository.UserRepository;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class BodyMetricService {

    private final BodyMetricRepository bodyMetricRepo;
    private final UserProfileRepository userProfileRepo;
    private final UserRepository userRepo;

    public BodyMetricService(BodyMetricRepository bodyMetricRepo, UserProfileRepository userProfileRepo, UserRepository userRepo) {
        this.userRepo = userRepo;
        this.bodyMetricRepo = bodyMetricRepo;
        this.userProfileRepo = userProfileRepo;
    }

    @Transactional
    public BodyMetricResponse createBodyMetric(String email, CreateBodyMetricRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException("user not found: " + email);
        }
        if (req.getMetricType() == null) {
            throw new DataCreationFailedException("metricType missing");
        }
        if (req.getValue() <= 0.0) {
            throw new DataCreationFailedException("value must be greater than 0");
        }
        BodyMetric bodyMetric = new BodyMetric(user, req.getMetricType(), req.getValue());
        bodyMetricRepo.save(bodyMetric);
        syncProfileMeasurementFromLatestMetric(user, req.getMetricType());
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

        // Sort by recordedAt descending (newest first)
        bodyMetrics = bodyMetrics.stream()
                .sorted((a, b) -> b.getRecordedAt().compareTo(a.getRecordedAt()))
                .toList();

        if (limit != null && limit > 0) {
            return bodyMetrics.stream().limit(limit).map(this::toBodyMetricResponse).toList();
        }
        return bodyMetrics.stream().map(this::toBodyMetricResponse).toList();
    }

    public List<BodyMetricResponse> getLatestBodyMetrics(String email, MetricType metricType) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException("user not found: " + email);
        }
        if (metricType != null) {
            BodyMetric bodyMetric = bodyMetricRepo.findTopByUserAndMetricTypeOrderByRecordedAtDescIdDesc(user, metricType);
            if (bodyMetric != null) {
                return List.of(toBodyMetricResponse(bodyMetric));
            }
            return new ArrayList<>();
        }
        List<BodyMetricResponse> bodyMetrics = new ArrayList<>();
        BodyMetric height = bodyMetricRepo.findTopByUserAndMetricTypeOrderByRecordedAtDescIdDesc(user, MetricType.HEIGHT);
        if (height != null) {
            bodyMetrics.add(toBodyMetricResponse(height));
        }
        BodyMetric weight = bodyMetricRepo.findTopByUserAndMetricTypeOrderByRecordedAtDescIdDesc(user, MetricType.WEIGHT);
        if (weight != null) {
            bodyMetrics.add(toBodyMetricResponse(weight));
        }
        return bodyMetrics;
    }

    @Transactional
    public BodyMetricResponse updateBodyMetric(String email, long id, CreateBodyMetricRequest req) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException("user not found: " + email);
        }
        BodyMetric bodyMetric = bodyMetricRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException("body metric not found: " + id));
        if (!bodyMetric.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException("body metric not found: " + id);
        }

        MetricType previousMetricType = bodyMetric.getMetricType();

        if (req.getMetricType() != null) {
            bodyMetric.setMetricType(req.getMetricType());
        }
        if (req.getValue() > 0.0) {
            bodyMetric.setValue(req.getValue());
        }

        bodyMetric.setUpdatedAt(Instant.now());
        bodyMetricRepo.save(bodyMetric);
        syncProfileMeasurementFromLatestMetric(user, previousMetricType);
        if (previousMetricType != bodyMetric.getMetricType()) {
            syncProfileMeasurementFromLatestMetric(user, bodyMetric.getMetricType());
        }
        return toBodyMetricResponse(bodyMetric);
    }

    @Transactional
    public void deleteBodyMetric(String email, long id) {
        User user = userRepo.findByEmail(email);
        if (user == null) {
            throw new DataNotFoundException("user not found: " + email);
        }
        BodyMetric bodyMetric = bodyMetricRepo.findById(id)
                .orElseThrow(() -> new DataNotFoundException("body metric not found: " + id));
        if (!bodyMetric.getUser().getEmail().equals(email)) {
            throw new DataNotFoundException("body metric not found: " + id);
        }

        MetricType deletedMetricType = bodyMetric.getMetricType();
        bodyMetricRepo.delete(bodyMetric);
        syncProfileMeasurementFromLatestMetric(user, deletedMetricType);
    }

    private void syncProfileMeasurementFromLatestMetric(User user, MetricType metricType) {
        if (metricType != MetricType.WEIGHT && metricType != MetricType.HEIGHT) {
            return;
        }

        UserProfile profile = userProfileRepo.findByUser(user);
        if (profile == null) {
            return;
        }

        BodyMetric latestMetric = bodyMetricRepo.findTopByUserAndMetricTypeOrderByRecordedAtDescIdDesc(user, metricType);
        if (latestMetric == null) {
            // Fallback behavior: keep existing user_profile value when no metric exists.
            return;
        }

        if (metricType == MetricType.WEIGHT) {
            profile.setWeight(latestMetric.getValue());
        } else if (metricType == MetricType.HEIGHT) {
            profile.setHeight(latestMetric.getValue());
        }

        userProfileRepo.save(profile);
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
                bodyMetric.getUpdatedAt());
    }
}

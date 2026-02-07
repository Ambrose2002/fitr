package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.MetricType;
import java.time.Instant;
import lombok.Getter;

@Getter
public class BodyMetricResponse {

    private final long id;
    private final long user_id;
    private final MetricType metricType;
    private final float value;
    private final Instant updatedAt;
    private final Instant createdAt;

    public BodyMetricResponse(long id, long user_id, MetricType metricType, float value, Instant updatedAt, Instant createdAt) {
        this.id = id;
        this.user_id = user_id;
        this.metricType = metricType;
        this.value = value;
        this.updatedAt = updatedAt;
        this.createdAt = createdAt;
    }
}

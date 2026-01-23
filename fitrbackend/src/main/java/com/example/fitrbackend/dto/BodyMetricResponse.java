package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.MetricType;
import java.time.Instant;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class BodyMetricResponse {

    private final long id;
    private final long user_id;
    private final MetricType metricType;
    private final float value;
    private final Instant recordedAt;
}

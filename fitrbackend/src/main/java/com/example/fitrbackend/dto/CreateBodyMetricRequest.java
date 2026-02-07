package com.example.fitrbackend.dto;

import com.example.fitrbackend.model.MetricType;
import lombok.Getter;

@Getter
public class CreateBodyMetricRequest {
    private MetricType metricType;
    private float value;
}

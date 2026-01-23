package com.example.fitrbackend.model;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import java.time.Instant;
import lombok.Getter;
import lombok.Setter;

/**
 * Represents a measurement of a user's body metrics.
 *
 * @author Jake Byrne
 */
@Entity
public class BodyMetric {

    /**
     * The unique identifier for the body metric.
     */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Getter
    private long id;

    /**
     * The user associated with the body metric.
     */
    @ManyToOne
    @JoinColumn(name = "user_id")
    @Getter
    private User user;

    /**
     * The type of metric associated with the body metric.
     */
    @Getter
    private MetricType metricType;

    /**
     * The value of the body metric.
     */
    @Getter
    @Setter
    private float value;

    /**
     * The time at which the body metric was recorded.
     */
    @Getter
    private Instant recordedAt;

    /**
     * Creates a new body metric.
     *
     * @param user the user associated with the body metric
     * @param metricType the type of metric associated with the body metric
     * @param value the value of the body metric
     */
    public BodyMetric(User user, MetricType metricType, float value) {
        this.user = user;
        this.metricType = metricType;
        this.value = value;
        this.recordedAt = Instant.now();
    }
}
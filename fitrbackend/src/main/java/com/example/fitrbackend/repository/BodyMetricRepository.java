package com.example.fitrbackend.repository;

import com.example.fitrbackend.model.BodyMetric;
import com.example.fitrbackend.model.MetricType;
import com.example.fitrbackend.model.User;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface BodyMetricRepository extends JpaRepository<BodyMetric, Long> {

    @Query("SELECT b FROM BodyMetric b WHERE b.user = ?1")
    List<BodyMetric> findByUser(User user);

    @Query("SELECT b FROM BodyMetric b WHERE b.user = ?1 AND b.metricType = ?2")
    List<BodyMetric> findByUserAndMetricType(User user, MetricType metricType);

    @Query("SELECT b FROM BodyMetric b WHERE b.user = ?1 AND b.metricType = ?2 ORDER BY b.recordedAt DESC LIMIT 1")
    BodyMetric findLatestByUserAndMetricType(User user, MetricType metricType);
}

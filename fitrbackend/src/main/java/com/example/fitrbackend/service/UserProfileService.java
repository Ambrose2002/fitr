package com.example.fitrbackend.service;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.example.fitrbackend.dto.CreateUserProfileRequest;
import com.example.fitrbackend.dto.UserProfileResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.BodyMetric;
import com.example.fitrbackend.model.MetricType;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.UserProfile;
import com.example.fitrbackend.repository.BodyMetricRepository;
import com.example.fitrbackend.repository.UserProfileRepository;
import com.example.fitrbackend.repository.UserRepository;

@Service
public class UserProfileService {

    private final BodyMetricRepository bodyMetricRepo;
    private final UserProfileRepository profileRepo;

    private final UserRepository userRepo;

    public UserProfileService(BodyMetricRepository bodyMetricRepo, UserProfileRepository profileRepo, UserRepository userRepo) {
        this.bodyMetricRepo = bodyMetricRepo;
        this.profileRepo = profileRepo;
        this.userRepo = userRepo;
    }

    public UserProfileResponse getUserProfile(Long id) {
        User user = userRepo.findById((id)).orElseThrow(() -> new DataNotFoundException(id, "user"));
        UserProfile profile = profileRepo.findByUser(user);
        if (profile == null) {
            throw new DataNotFoundException(id, "userProfile");
        }
        return toUserProfileResponse(profile);
    }

    @Transactional
    public UserProfileResponse createUserProfile(CreateUserProfileRequest req, Long id) {
        User user = userRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "user"));
        UserProfile profile = profileRepo.findByUser(user);
        if (profile != null) {
            throw new DataCreationFailedException("User already has an existing profile");
        }
        UserProfile newProfile = new UserProfile(user, req.getGender(), req.getHeight(), req.getWeight(), req.getExperienceLevel(), req.getGoal(), req.getPreferredWeightUnit(), req.getPreferredDistanceUnit());
        UserProfile savedProfile = profileRepo.save(newProfile);
        seedBodyMetricsForProfile(user, savedProfile.getHeight(), savedProfile.getWeight());
        return toUserProfileResponse(savedProfile);
    }

    @Transactional
    public UserProfileResponse updateUserProfile(CreateUserProfileRequest req, Long id) {
        User user = userRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "user"));
        UserProfile profile = profileRepo.findByUser(user);
        if (profile == null) {
            throw new DataNotFoundException(id, "userProfile");
        }
        boolean hasHeightUpdate = req.getHeight() != 0;
        boolean hasWeightUpdate = req.getWeight() != 0;

        if (req.getGender() != null) {
            profile.setGender(req.getGender());
        }

        if (req.getHeight() != 0) {
            profile.setHeight(req.getHeight());
        }

        if (req.getWeight() != 0) {
            profile.setWeight(req.getWeight());
        }

        if (req.getExperienceLevel() != null) {
            profile.setExperienceLevel(req.getExperienceLevel());
        }

        if (req.getGoal() != null) {
            profile.setGoal(req.getGoal());
        }

        if (req.getPreferredWeightUnit() != null) {
            profile.setPreferredWeightUnit(req.getPreferredWeightUnit());
        }

        if (req.getPreferredDistanceUnit() != null) {
            profile.setPreferredDistanceUnit(req.getPreferredDistanceUnit());
        }

        UserProfile savedProfile = profileRepo.save(profile);

        if (hasHeightUpdate && savedProfile.getHeight() > 0) {
            bodyMetricRepo.save(new BodyMetric(user, MetricType.HEIGHT, savedProfile.getHeight()));
        }

        if (hasWeightUpdate && savedProfile.getWeight() > 0) {
            bodyMetricRepo.save(new BodyMetric(user, MetricType.WEIGHT, savedProfile.getWeight()));
        }

        return toUserProfileResponse(savedProfile);
    }

    private UserProfileResponse toUserProfileResponse(UserProfile profile) {
        float resolvedHeight = resolveProfileMeasurement(profile, MetricType.HEIGHT);
        float resolvedWeight = resolveProfileMeasurement(profile, MetricType.WEIGHT);
        return new UserProfileResponse(
                profile.getId(),
                profile.getUser().getId(),
                profile.getUser().getFirstname(),
                profile.getUser().getLastname(),
                profile.getUser().getEmail(),
                profile.getGender(),
                resolvedHeight,
                resolvedWeight,
                profile.getExperienceLevel(),
                profile.getGoal(),
                profile.getPreferredWeightUnit(),
                profile.getPreferredDistanceUnit(),
                profile.getCreatedAt()
        );
    }

    private float resolveProfileMeasurement(UserProfile profile, MetricType metricType) {
        BodyMetric latestMetric = bodyMetricRepo.findTopByUserAndMetricTypeOrderByRecordedAtDescIdDesc(
                profile.getUser(),
                metricType
        );

        if (latestMetric != null) {
            return latestMetric.getValue();
        }

        if (metricType == MetricType.HEIGHT) {
            return profile.getHeight();
        }

        return profile.getWeight();
    }

    private void seedBodyMetricsForProfile(User user, float height, float weight) {
        if (height > 0) {
            bodyMetricRepo.save(new BodyMetric(user, MetricType.HEIGHT, height));
        }

        if (weight > 0) {
            bodyMetricRepo.save(new BodyMetric(user, MetricType.WEIGHT, weight));
        }
    }
}

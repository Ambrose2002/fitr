package com.example.fitrbackend.service;

import org.springframework.stereotype.Service;

import com.example.fitrbackend.dto.CreateUserProfileRequest;
import com.example.fitrbackend.dto.UserProfileResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.exception.DataNotFoundException;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.UserProfile;
import com.example.fitrbackend.repository.UserProfileRepository;
import com.example.fitrbackend.repository.UserRepository;

@Service
public class UserProfileService {

    private final UserProfileRepository profileRepo;

    private final UserRepository userRepo;

    public UserProfileService(UserProfileRepository profileRepo, UserRepository userRepo) {
        this.profileRepo = profileRepo;
        this.userRepo = userRepo;
    }

    public UserProfileResponse getUserProfile(Long id) {
        User user = userRepo.findById((id)).orElseThrow(() -> new DataNotFoundException(id, "user"));
        UserProfile profile = profileRepo.findByUser(user);
        if (profile == null) {
            throw new DataNotFoundException(id, "userProfile");
        }
        return toUserProfileResponse(profileRepo.findByUser(user));
    }

    public UserProfileResponse createUserProfile(CreateUserProfileRequest req, Long id) {
        User user = userRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "user"));
        UserProfile profile = profileRepo.findByUser(user);
        if (profile != null) {
            throw new DataCreationFailedException("User already has an existing profile");
        }
        UserProfile newProfile = new UserProfile(user, req.getGender(), req.getHeight(), req.getWeight(), req.getExperienceLevel(), req.getGoal(), req.getPreferredWeightUnit(), req.getPreferredDistanceUnit());
        return toUserProfileResponse(profileRepo.save(newProfile));
    }

    public UserProfileResponse updateUserProfile(CreateUserProfileRequest req, Long id) {
        User user = userRepo.findById(id).orElseThrow(() -> new DataNotFoundException(id, "user"));
        UserProfile profile = profileRepo.findByUser(user);
        if (profile == null) {
            throw new DataNotFoundException(id, "userProfile");
        }

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

        return toUserProfileResponse(profileRepo.save(profile));
    }

    private UserProfileResponse toUserProfileResponse(UserProfile profile) {
        return new UserProfileResponse(
                profile.getId(),
                profile.getUser().getId(),
                profile.getUser().getFirstname(),
                profile.getUser().getLastname(),
                profile.getUser().getEmail(),
                profile.getGender(),
                profile.getHeight(),
                profile.getWeight(),
                profile.getExperienceLevel(),
                profile.getGoal(),
                profile.getPreferredWeightUnit(),
                profile.getPreferredDistanceUnit(),
                profile.getCreatedAt()
        );
    }
}

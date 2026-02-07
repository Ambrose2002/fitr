package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateSetLogRequest;
import com.example.fitrbackend.dto.SetLogResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.service.WorkoutSessionService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/workout-exercises/{workoutExerciseId}/sets")
public class SetLogController {

    private final WorkoutSessionService workoutSessionService;

    public SetLogController(WorkoutSessionService workoutSessionService) {
        this.workoutSessionService = workoutSessionService;
    }

    @PostMapping
    public List<SetLogResponse> createSetLog(@PathVariable Long workoutExerciseId, @RequestBody CreateSetLogRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.createSetLog( email, workoutExerciseId, req);
    }

    @PutMapping("/{setLogId}")
    public SetLogResponse updateSetLog(@PathVariable Long workoutExerciseId, @PathVariable Long setLogId, @RequestBody CreateSetLogRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.updateSetLog(email, workoutExerciseId, setLogId, req);
    }

    @DeleteMapping("/{setLogId}")
    public void deleteSetLog(@PathVariable Long workoutExerciseId, @PathVariable Long setLogId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        workoutSessionService.deleteSetLog(email, workoutExerciseId, setLogId);
    }

    @GetMapping
    public List<SetLogResponse> getSetLogs(@PathVariable Long workoutExerciseId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return workoutSessionService.getSetLogs(email, workoutExerciseId);
    }
}

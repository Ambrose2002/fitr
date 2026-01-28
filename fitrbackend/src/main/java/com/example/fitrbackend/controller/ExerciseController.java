package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateExerciseRequest;
import com.example.fitrbackend.dto.ExerciseResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.service.ExerciseService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/exercise")
public class ExerciseController {

    private final ExerciseService exerciseService;

    public ExerciseController(ExerciseService exerciseService) {
        this.exerciseService = exerciseService;
    }

    @GetMapping
    public List<ExerciseResponse> getExercises(@RequestParam(required = true) boolean systemOnly) {

        if (systemOnly) {
            return exerciseService.getAllSystemDefinedExercises();
        } else {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null) {
                throw new AuthenticationFailedException("auth not found");
            }
            String email = auth.getName();

            return exerciseService.getAllExercisesByUserAndSystem(email);
        }
    }

    @GetMapping("/{id}")
    public ExerciseResponse getOneExercise(@PathVariable Long id) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return exerciseService.getExercise(id, email);
    }

    @PostMapping
    public ExerciseResponse createExercise(@RequestBody CreateExerciseRequest req, @RequestParam(required = true, defaultValue = "false" ) boolean isSystemDefined) {

        if (isSystemDefined) {
            return exerciseService.createExercise(req);
        } else {
            Authentication auth = SecurityContextHolder.getContext().getAuthentication();
            if (auth == null) {
                throw new AuthenticationFailedException("auth not found");
            }
            String email = auth.getName();

            return exerciseService.createExercise(email, req);
        }

    }

    @PutMapping("/{id}")
    public ExerciseResponse updateExercise(@PathVariable Long id, @RequestBody CreateExerciseRequest req) {
        return exerciseService.updateExercise(req, id);
    }
}

package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreateExerciseRequest;
import com.example.fitrbackend.dto.ExerciseResponse;
import com.example.fitrbackend.service.ExerciseService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/exercise")
public class ExerciseController {

    private final ExerciseService exerciseService;

    public ExerciseController(ExerciseService exerciseService) {
        this.exerciseService = exerciseService;
    }

    @GetMapping("/{id}")
    public ExerciseResponse getOneExercise(@PathVariable Long id) {

        return exerciseService.getExercise(id);
    }

    @PostMapping
    public ExerciseResponse postExercise(@RequestBody CreateExerciseRequest req) {
        return exerciseService.createExercise(req);
    }

    @PutMapping("/{id}")
    public ExerciseResponse updateExercise(@PathVariable Long id, @RequestBody CreateExerciseRequest req) {
        return exerciseService.updateExercise(req, id);
    }
}

package com.example.fitrbackend.controller;

import com.example.fitrbackend.dto.CreatePlanDayExerciseRequest;
import com.example.fitrbackend.dto.PlanExerciseResponse;
import com.example.fitrbackend.exception.AuthenticationFailedException;
import com.example.fitrbackend.service.PlanDaysService;
import java.util.List;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/plan-days")
public class PlanDaysController {

    private final PlanDaysService planDaysService;

    public PlanDaysController(PlanDaysService planDayService) {
        this.planDaysService = planDayService;
    }

    @PostMapping("/{dayId}/exercises")
    public PlanExerciseResponse addExerciseToPlanDay(@PathVariable Long dayId, @RequestBody CreatePlanDayExerciseRequest req) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return planDaysService.addExerciseToPlanDay(email, dayId, req);

    }

    @GetMapping("/{dayId}/exercises")
    public List<PlanExerciseResponse> getPlanDayExercises(@PathVariable Long dayId) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null) {
            throw new AuthenticationFailedException("auth not found");
        }
        String email = auth.getName();
        return planDaysService.getPlanDayExercises(email, dayId);
    }
}

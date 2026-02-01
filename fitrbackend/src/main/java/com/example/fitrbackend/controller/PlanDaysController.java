package com.example.fitrbackend.controller;

import com.example.fitrbackend.service.PlanDaysService;
import org.springframework.web.bind.annotation.PostMapping;
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
    public void addExerciseToPlanDay() {
        planDaysService.addExerciseToPlanDay();
    }
}

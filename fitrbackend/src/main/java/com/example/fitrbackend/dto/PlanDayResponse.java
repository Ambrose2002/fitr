package com.example.fitrbackend.dto;

import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class PlanDayResponse {

        private final long id;
        private final long workout_plan_id;
        private final int dayNumber;
        private final String name;
}

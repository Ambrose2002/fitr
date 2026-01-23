package com.example.fitrbackend.dto;

import lombok.Getter;

@Getter
public class PlanDayResponse {

        private final long id;
        private final long workout_plan_id;
        private final int dayNumber;
        private final String name;

        public PlanDayResponse(long id, long workout_plan_id, int dayNumber, String name) {
            this.id = id;
            this.workout_plan_id = workout_plan_id;
            this.dayNumber = dayNumber;
            this.name = name;
        }
}

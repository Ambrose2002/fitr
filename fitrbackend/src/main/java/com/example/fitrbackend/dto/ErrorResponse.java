package com.example.fitrbackend.dto;

import java.time.Instant;
import lombok.Getter;

@Getter
public class ErrorResponse {

    private final String message;
    private final int status;
    private final Instant timestamp;

    public ErrorResponse(String message, int status) {
        this.message = message;
        this.status = status;
        this.timestamp = Instant.now();
    }
}

package com.example.fitrbackend.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

public class CreateLoginRequest {

    @NotBlank(message = "email is required")
    @Getter
    @Setter
    private String email;

    @NotBlank(message = "password is required")
    @Getter
    @Setter
    private String password;
}

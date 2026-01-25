package com.example.fitrbackend.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import jakarta.validation.constraints.NotBlank;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class CreateUserRequest {

    @NotBlank(message = "email is required")
    @JsonProperty("email")
    private String email;

    @NotBlank(message = "password is required")
    @JsonProperty("password")
    private String password;

    @NotBlank(message = "first name is required")
    @JsonProperty("firstname")
    private String firstName;

    @NotBlank(message = "last name is required")
    @JsonProperty("lastname")
    private String lastName;
}

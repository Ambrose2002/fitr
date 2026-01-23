package com.example.fitrbackend.exception;

public class DataNotFoundException extends RuntimeException {

    public DataNotFoundException(Long id, String dataName) {
        super(dataName + " not found: " + id);
    }
}

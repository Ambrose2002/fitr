package com.example.fitrbackend.exception;

public class DataNotFoundException extends RuntimeException {

    public DataNotFoundException(Long id, String dataName) {
        super(dataName + " not found: " + id);
    }

    public DataNotFoundException(String message) {
        super("Data not found: " + message);
    }
}

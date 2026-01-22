package com.example.fitrbackend.dto;

import lombok.Getter;

public class LocationResponse {

    @Getter
    private final long id;
    @Getter
    private final long user_id;
    @Getter
    private final String name;
    @Getter
    private final String address;

    public LocationResponse(long id, long user_id, String name, String address) {
        this.id = id;
        this.user_id = user_id;
        this.name = name;
        this.address = address;
    }
}

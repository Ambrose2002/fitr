# Fitr

A comprehensive fitness tracking application with a Spring Boot backend API.

## Overview

Fitr allows users to manage workout plans, track exercise sessions, log performance metrics, and monitor body composition. The backend provides a RESTful API for all fitness tracking operations.

## Features

- User authentication and profile management
- Create and manage workout plans with structured daily routines
- Track workout sessions with detailed exercise logging
- Log performance metrics (sets, reps, weight, duration, distance, calories)
- Monitor body metrics (weight, height)
- Manage workout locations

## Tech Stack

- **Backend**: Spring Boot (Java)
- **Database**: PostgreSQL
- **Authentication**: JWT

## Getting Started

For detailed API documentation including endpoints, request/response formats, and authentication, see [API_DOCUMENTATION.md](fitrbackend/API_DOCUMENTATION.md).

The frontend is coming soon.

## Dev Data Reset and Reseed

For local testing with a clean database and fresh system exercise catalog:

1. Reset all app data (users, profiles, workouts, plans, metrics, exercises):
   - `cd fitrbackend`
   - `./scripts/reset_dev_data.sh`
   - This preserves Flyway metadata but clears prior exercise-seed migration history so the system catalog reseeds on next migrate.
2. Run Flyway migrations (including system exercise seeding):
   - `./scripts/migrate.sh`
3. Start backend/frontend and sign up again in the app.

## Container Deployment

Build image:
- `docker build -t fitrbackend:latest fitrbackend`

Run container:
- `docker run --name fitrbackend -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e SPRING_DATASOURCE_URL='jdbc:postgresql://<host>:5432/<db>' \
  -e SPRING_DATASOURCE_USERNAME='<username>' \
  -e SPRING_DATASOURCE_PASSWORD='<password>' \
  -e JWT_KEY='<at-least-32-byte-secret>' \
  fitrbackend:latest`

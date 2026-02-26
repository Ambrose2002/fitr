# FitrBackend API Documentation

## Table of Contents

1. [Introduction](#introduction)
2. [Base URL & Authentication](#base-url--authentication)
3. [Error Handling](#error-handling)
4. [Data Types & Enums](#data-types--enums)
5. [API Endpoints](#api-endpoints)
   - [Authentication](#authentication)
   - [User Management](#user-management)
   - [Exercises](#exercises)
   - [Workout Plans](#workout-plans)
   - [Plan Days](#plan-days)
   - [Workout Sessions](#workout-sessions)
   - [Body Metrics](#body-metrics)
   - [Locations](#locations)

---

## Introduction

The FitrBackend API provides a comprehensive fitness tracking system that allows users to:

- Manage user profiles and preferences
- Create and manage workout plans with structured days
- Track workout sessions with detailed exercise logging
- Record performance metrics (sets, reps, weight, duration, distance, calories)
- Monitor body metrics (weight, height)
- Manage workout locations

**Base URL**: `http://localhost:8080`

**API Version**: v1

**Database**: PostgreSQL

---

## Base URL & Authentication

### Authentication Method

All endpoints (except `/auth/login` and `/auth/signup`) require JWT token-based authentication.

### How to Obtain Token

1. **Sign Up** - Create a new user account
2. **Login** - Authenticate with email and password to receive JWT token
3. Include the token in subsequent requests via `Authorization: Bearer {token}` header

### Token Usage

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## Error Handling

### Error Response Format

All errors follow this standard format:

```json
{
  "message": "Error description",
  "timestamp": "2024-02-07T10:30:45.123Z",
  "path": "/api/resource/{id}"
}
```

### Common HTTP Status Codes

| Status Code | Description                          |
| ----------- | ------------------------------------ |
| 200         | Success                              |
| 201         | Created                              |
| 204         | No Content                           |
| 400         | Bad Request (validation error)       |
| 401         | Unauthorized (missing/invalid token) |
| 404         | Not Found                            |
| 500         | Internal Server Error                |

### Common Error Scenarios

| Error                                            | Cause                                  |
| ------------------------------------------------ | -------------------------------------- |
| `Invalid email or password`                      | Wrong credentials during login         |
| `User with email {email} exists`                 | Account already exists                 |
| `auth not found`                                 | Missing or invalid JWT token           |
| `Could not find workouts within the constraints` | Invalid date range or query parameters |

---

## Data Types & Enums

### Gender Enum

Possible values:

- `MALE`
- `FEMALE`
- `OTHER`

### Goal Enum

User fitness goals:

- `STRENGTH` - Build strength
- `HYPERTROPHY` - Build muscle mass
- `FAT_LOSS` - Lose weight
- `GENERAL` - General fitness

### ExperienceLevel Enum

User experience in fitness:

- `BEGINNER` - New to fitness
- `INTERMEDIATE` - Some experience
- `ADVANCED` - Expert level

### MetricType Enum

Body metric types:

- `WEIGHT` - Body weight
- `HEIGHT` - Body height

### Unit Enum

Measurement units:

- `KG` - Kilograms
- `LB` - Pounds
- `KM` - Kilometers
- `MI` - Miles
- `CM` - Centimeters

### MeasurementType Enum

Exercise measurement types:

- `REPS` - Measured by repetitions only
- `TIME` - Measured by time only
- `REPS_AND_TIME` - Measured by reps and time
- `TIME_AND_WEIGHT` - Measured by time and weight
- `REPS_AND_WEIGHT` - Measured by reps and weight
- `DISTANCE_AND_TIME` - Measured by distance and time
- `CALORIES_AND_TIME` - Measured by calories and time

---

## API Endpoints

### Authentication

#### 1. Login

Create a new session and receive JWT token.

**Endpoint**: `POST /auth/login`

**Request Headers**:

```
Content-Type: application/json
```

**Request Body**:

```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

**Response** (200 OK):

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response** (401 Unauthorized):

```json
{
  "message": "Invalid email or password",
  "timestamp": "2024-02-07T10:30:45.123Z",
  "status": 401
}
```

**Validation Rules**:

- Email is required and must be valid
- Password is required and non-empty

---

#### 2. Sign Up

Register a new user account.

**Endpoint**: `POST /auth/signup`

**Request Headers**:

```
Content-Type: application/json
```

**Request Body**:

```json
{
  "email": "newuser@example.com",
  "password": "password123",
  "firstname": "John",
  "lastname": "Doe"
}
```

**Response** (200 OK):

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Response** (409 Conflict):

```json
{
  "message": "User with email newuser@example.com exists",
  "timestamp": "2024-02-07T10:30:45.123Z",
  "status": 409
}
```

**Validation Rules**:

- Email is required, must be unique
- Password is required (non-empty)
- First name is required
- Last name is required

---

### User Management

#### 1. Get Current User Profile

Retrieve the authenticated user's basic information.

**Endpoint**: `GET /api/me`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response** (200 OK):

```json
{
  "id": 1,
  "firstname": "John",
  "lastname": "Doe",
  "email": "john@example.com",
  "createdAt": "2024-01-15T08:30:00Z",
  "isActive": true
}
```

**Error Response** (401 Unauthorized):

```json
{
  "message": "auth not found",
  "timestamp": "2024-02-07T10:30:45.123Z",
  "path": "/api/me"
}
```

---

#### 2. Update Current User

Update the authenticated user's name.

**Endpoint**: `POST /api/me`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "firstname": "Jane",
  "lastname": "Smith"
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "firstname": "Jane",
  "lastname": "Smith",
  "email": "john@example.com",
  "createdAt": "2024-01-15T08:30:00Z",
  "isActive": true
}
```

---

#### 3. Get User Profile

Retrieve the authenticated user's detailed fitness profile.

**Endpoint**: `GET /api/me/profile`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response** (200 OK):

```json
{
  "id": 1,
  "userId": 1,
  "firstname": "John",
  "lastname": "Doe",
  "email": "john@example.com",
  "gender": "MALE",
  "height": 180.5,
  "weight": 85.0,
  "experience": "INTERMEDIATE",
  "goal": "HYPERTROPHY",
  "preferredWeightUnit": "KG",
  "preferredDistanceUnit": "KM",
  "createdAt": "2024-01-15T08:30:00Z"
}
```

---

#### 4. Create User Profile

Create a fitness profile for the authenticated user.

**Endpoint**: `POST /api/me/profile`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "gender": "MALE",
  "height": 180.5,
  "weight": 85.0,
  "experienceLevel": "INTERMEDIATE",
  "goal": "HYPERTROPHY",
  "preferredWeightUnit": "KG",
  "preferredDistanceUnit": "KM"
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "userId": 1,
  "firstname": "John",
  "lastname": "Doe",
  "email": "john@example.com",
  "gender": "MALE",
  "height": 180.5,
  "weight": 85.0,
  "experience": "INTERMEDIATE",
  "goal": "HYPERTROPHY",
  "preferredWeightUnit": "KG",
  "preferredDistanceUnit": "KM",
  "createdAt": "2024-02-07T10:30:45.123Z"
}
```

**Supported Values**:

- `gender`: MALE, FEMALE, OTHER
- `experienceLevel`: BEGINNER, INTERMEDIATE, ADVANCED
- `goal`: STRENGTH, HYPERTROPHY, FAT_LOSS, GENERAL
- `preferredWeightUnit`: KG, LB
- `preferredDistanceUnit`: KM, MI

---

#### 5. Update User Profile

Update an existing user fitness profile.

**Endpoint**: `PUT /api/me/profile`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "gender": "MALE",
  "height": 181.0,
  "weight": 84.5,
  "experienceLevel": "ADVANCED",
  "goal": "STRENGTH",
  "preferredWeightUnit": "KG",
  "preferredDistanceUnit": "KM"
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "userId": 1,
  "firstname": "John",
  "lastname": "Doe",
  "email": "john@example.com",
  "gender": "MALE",
  "height": 181.0,
  "weight": 84.5,
  "experience": "ADVANCED",
  "goal": "STRENGTH",
  "preferredWeightUnit": "KG",
  "preferredDistanceUnit": "KM",
  "createdAt": "2024-01-15T08:30:00Z"
}
```

---

### Exercises

#### 1. Get All Exercises

Retrieve exercises based on scope (system-defined or user's combined list).

**Endpoint**: `GET /api/exercise?systemOnly={boolean}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Query Parameters**:
| Parameter | Type | Required | Description |
|---|---|---|---|
| `systemOnly` | boolean | Yes | If `true`, return only system-defined exercises. If `false`, return system-defined + user-created exercises |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "name": "Bench Press",
    "measurementType": "REPS_AND_WEIGHT",
    "isSystemDefined": true,
    "createdAt": "2024-01-10T08:30:00Z"
  },
  {
    "id": 2,
    "name": "Running",
    "measurementType": "DISTANCE_AND_TIME",
    "isSystemDefined": false,
    "createdAt": "2024-02-01T10:30:00Z"
  }
]
```

**Examples**:

- Get system exercises only: `GET /api/exercise?systemOnly=true`
- Get all exercises (system + user): `GET /api/exercise?systemOnly=false`

---

#### 2. Get Single Exercise

Retrieve a specific exercise by ID.

**Endpoint**: `GET /api/exercise/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The exercise ID |

**Response** (200 OK):

```json
{
  "id": 1,
  "name": "Bench Press",
  "measurementType": "REPS_AND_WEIGHT",
  "isSystemDefined": true,
  "createdAt": "2024-01-10T08:30:00Z"
}
```

---

#### 3. Create Exercise

Create a new exercise (either system-defined or user-specific).

**Endpoint**: `POST /api/exercise?isSystemDefined={boolean}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Query Parameters**:
| Parameter | Type | Required | Description |
|---|---|---|---|
| `isSystemDefined` | boolean | No | Default is `false`. Set to `true` to create a system-defined exercise |

**Request Body**:

```json
{
  "name": "Custom Squat",
  "measurementType": "REPS_AND_WEIGHT"
}
```

**Response** (200 OK):

```json
{
  "id": 3,
  "name": "Custom Squat",
  "measurementType": "REPS_AND_WEIGHT",
  "isSystemDefined": false,
  "createdAt": "2024-02-07T10:30:45.123Z"
}
```

**Supported MeasurementTypes**:

- `REPS` - Repetitions only
- `TIME` - Duration only
- `REPS_AND_TIME` - Reps and duration
- `TIME_AND_WEIGHT` - Time and weight
- `REPS_AND_WEIGHT` - Reps and weight
- `DISTANCE_AND_TIME` - Distance and time
- `CALORIES_AND_TIME` - Calories and time

---

#### 4. Update Exercise

Update an existing exercise.

**Endpoint**: `PUT /api/exercise/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The exercise ID |

**Request Body**:

```json
{
  "name": "Barbell Bench Press",
  "measurementType": "REPS_AND_WEIGHT"
}
```

**Response** (200 OK):

```json
{
  "id": 3,
  "name": "Barbell Bench Press",
  "measurementType": "REPS_AND_WEIGHT",
  "isSystemDefined": false,
  "createdAt": "2024-02-07T10:30:45.123Z"
}
```

---

### Workout Plans

#### 1. Get All Workout Plans

Retrieve all workout plans for the authenticated user.

**Endpoint**: `GET /api/plans`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "user_id": 1,
    "name": "Upper Body Split",
    "createdAt": "2024-02-01T10:30:00Z",
    "isActive": true
  },
  {
    "id": 2,
    "user_id": 1,
    "name": "Lower Body Split",
    "createdAt": "2024-02-02T10:30:00Z",
    "isActive": false
  }
]
```

---

#### 2. Create Workout Plan

Create a new workout plan.

**Endpoint**: `POST /api/plans`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "name": "Full Body Routine"
}
```

**Response** (200 OK):

```json
{
  "id": 3,
  "user_id": 1,
  "name": "Full Body Routine",
  "createdAt": "2024-02-07T10:30:45.123Z",
  "isActive": true
}
```

---

#### 3. Get Single Workout Plan

Retrieve a specific workout plan with its days.

**Endpoint**: `GET /api/plans/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The workout plan ID |

**Response** (200 OK):

```json
{
  "id": 1,
  "user_id": 1,
  "name": "Upper Body Split",
  "createdAt": "2024-02-01T10:30:00Z",
  "isActive": true
}
```

---

#### 4. Update Workout Plan

Update a workout plan's details.

**Endpoint**: `PUT /api/plans/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The workout plan ID |

**Request Body**:

```json
{
  "name": "Updated Upper Body Split",
  "isActive": true
}
```

**Request Body Notes**:

- `name` - Required. The updated plan name
- `isActive` - Optional. Set to true to make this the active plan, false to deactivate it. If not provided, the current value is preserved.

**Response** (200 OK):

```json
{
  "id": 1,
  "user_id": 1,
  "name": "Updated Upper Body Split",
  "createdAt": "2024-02-01T10:30:00Z",
  "isActive": true
}
```

---

#### 5. Delete Workout Plan

Delete a workout plan and all associated data.

**Endpoint**: `DELETE /api/plans/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The workout plan ID |

**Response** (204 No Content):

```
(Empty response body)
```

---

#### 6. Get All Days in Workout Plan

Retrieve all days in a workout plan.

**Endpoint**: `GET /api/plans/{planId}/days`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `planId` | Long | The workout plan ID |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "workout_plan_id": 1,
    "dayNumber": 1,
    "name": "Monday - Chest & Triceps"
  },
  {
    "id": 2,
    "workout_plan_id": 1,
    "dayNumber": 2,
    "name": "Wednesday - Back & Biceps"
  }
]
```

---

#### 7. Get Single Day in Workout Plan

Retrieve a specific day from a workout plan.

**Endpoint**: `GET /api/plans/{planId}/days/{dayId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `planId` | Long | The workout plan ID |
| `dayId` | Long | The plan day ID |

**Response** (200 OK):

```json
{
  "id": 1,
  "workout_plan_id": 1,
  "dayNumber": 1,
  "name": "Monday - Chest & Triceps"
}
```

---

#### 8. Add Day to Workout Plan

Add a new day to a workout plan.

**Endpoint**: `POST /api/plans/{planId}/days`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `planId` | Long | The workout plan ID |

**Request Body**:

```json
{
  "dayNumber": 3,
  "name": "Friday - Legs"
}
```

**Response** (200 OK):

```json
{
  "id": 3,
  "workout_plan_id": 1,
  "dayNumber": 3,
  "name": "Friday - Legs"
}
```

---

#### 9. Update Day in Workout Plan

Update a day's details within a workout plan.

**Endpoint**: `PUT /api/plans/{planId}/days/{dayId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `planId` | Long | The workout plan ID |
| `dayId` | Long | The plan day ID |

**Request Body**:

```json
{
  "dayNumber": 1,
  "name": "Monday - Chest, Shoulders & Triceps"
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "workout_plan_id": 1,
  "dayNumber": 1,
  "name": "Monday - Chest, Shoulders & Triceps"
}
```

---

#### 10. Delete Day in Workout Plan

Delete a specific day from a workout plan.

**Endpoint**: `DELETE /api/plans/{planId}/days/{dayId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `planId` | Long | The workout plan ID |
| `dayId` | Long | The plan day ID |

**Response** (204 No Content):

```
(Empty response body)
```

---

### Plan Days

Plan Days endpoints manage exercises assigned to specific days within a workout plan.

#### 1. Add Exercise to Plan Day

Assign an exercise to a specific plan day with target metrics.

**Endpoint**: `POST /api/plan-days/{dayId}/exercises`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `dayId` | Long | The plan day ID |

**Request Body**:

```json
{
  "exerciseId": 1,
  "targetSets": 3,
  "targetReps": 8,
  "targetDurationSeconds": 0,
  "targetDistance": 0,
  "targetCalories": 0
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "plan_day_id": 1,
  "exercise_id": 1,
  "targetSets": 3,
  "targetReps": 8,
  "targetDurationSeconds": 0,
  "targetDistance": 0,
  "targetCalories": 0
}
```

**Notes**:

- Set unused metrics to 0
- The metrics should align with the exercise's `measurementType`

---

#### 2. Get Exercises in Plan Day

Retrieve all exercises assigned to a plan day.

**Endpoint**: `GET /api/plan-days/{dayId}/exercises`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `dayId` | Long | The plan day ID |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "plan_day_id": 1,
    "exercise_id": 1,
    "targetSets": 3,
    "targetReps": 8,
    "targetDurationSeconds": 0,
    "targetDistance": 0,
    "targetCalories": 0
  }
]
```

---

#### 3. Get Single Exercise in Plan Day

Retrieve a specific exercise from a plan day.

**Endpoint**: `GET /api/plan-days/{dayId}/exercises/{exerciseId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `dayId` | Long | The plan day ID |
| `exerciseId` | Long | The plan exercise ID (the `id` returned by plan day exercises). This endpoint also accepts the catalog exercise ID for backward compatibility. |

**Response** (200 OK):

```json
{
  "id": 1,
  "plan_day_id": 1,
  "exercise_id": 1,
  "targetSets": 3,
  "targetReps": 8,
  "targetDurationSeconds": 0,
  "targetDistance": 0,
  "targetCalories": 0,
  "targetWeight": 0
}
```

---

#### 4. Update Exercise in Plan Day

Update target metrics for an exercise in a plan day.

**Endpoint**: `PUT /api/plan-days/{dayId}/exercises/{exerciseId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `dayId` | Long | The plan day ID |
| `exerciseId` | Long | The plan exercise ID (the `id` returned by plan day exercises). This endpoint also accepts the catalog exercise ID for backward compatibility. |

**Request Body**:

```json
{
  "exerciseId": 1,
  "targetSets": 4,
  "targetReps": 10,
  "targetDurationSeconds": 0,
  "targetDistance": 0,
  "targetCalories": 0,
  "targetWeight": 0
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "plan_day_id": 1,
  "exercise_id": 1,
  "targetSets": 4,
  "targetReps": 10,
  "targetDurationSeconds": 0,
  "targetDistance": 0,
  "targetCalories": 0,
  "targetWeight": 0
}
```

---

#### 5. Delete Exercise from Plan Day

Remove an exercise from a plan day.

**Endpoint**: `DELETE /api/plan-days/{dayId}/exercises/{exerciseId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `dayId` | Long | The plan day ID |
| `exerciseId` | Long | The exercise ID |

**Response** (204 No Content):

```
(Empty response body)
```

---

### Workout Sessions

Workout Sessions represent actual workout instances performed by the user.

#### 1. Create Workout Session

Start a new workout session.

**Endpoint**: `POST /api/workouts`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "locationId": 1,
  "notes": "Great workout today",
  "endTime": "2024-02-07T11:30:00Z"
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "user_id": 1,
  "workout_location_id": 1,
  "startTime": "2024-02-07T10:00:00Z",
  "endTime": "2024-02-07T11:30:00Z",
  "notes": "Great workout today",
  "workoutExercises": []
}
```

---

#### 2. Get Workout Sessions

Retrieve user's workout sessions with optional filtering.

**Endpoint**: `GET /api/workouts?limit={limit}&startDate={startDate}&endDate={endDate}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Query Parameters**:
| Parameter | Type | Required | Format | Description |
|---|---|---|---|---|
| `limit` | Integer | No | Number | Maximum number of results (defaults to all) |
| `startDate` | String | No | ISO 8601 | Start date for filtering (inclusive) |
| `endDate` | String | No | ISO 8601 | End date for filtering (inclusive) |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "user_id": 1,
    "workout_location_id": 1,
    "startTime": "2024-02-07T10:00:00Z",
    "endTime": "2024-02-07T11:30:00Z",
    "notes": "Great workout today",
    "workoutExercises": []
  }
]
```

**Examples**:

- Get last 5 workouts: `GET /api/workouts?limit=5`
- Get workouts from February: `GET /api/workouts?startDate=2024-02-01T00:00:00Z&endDate=2024-02-29T23:59:59Z`

---

#### 3. Get Single Workout Session

Retrieve details of a specific workout session.

**Endpoint**: `GET /api/workouts/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The workout session ID |

**Response** (200 OK):

```json
{
  "id": 1,
  "user_id": 1,
  "workout_location_id": 1,
  "startTime": "2024-02-07T10:00:00Z",
  "endTime": "2024-02-07T11:30:00Z",
  "notes": "Great workout today",
  "workoutExercises": [
    {
      "id": 1,
      "workout_session_id": 1,
      "exercise": {
        "id": 1,
        "name": "Bench Press",
        "measurementType": "REPS_AND_WEIGHT",
        "isSystemDefined": true,
        "createdAt": "2024-01-10T08:30:00Z"
      },
      "setLogs": []
    }
  ]
}
```

---

#### 4. Update Workout Session

Update a workout session's details.

**Endpoint**: `PUT /api/workouts/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The workout session ID |

**Request Body**:

```json
{
  "locationId": 2,
  "notes": "Updated notes - felt really strong today",
  "endTime": "2024-02-07T11:45:00Z"
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "user_id": 1,
  "workout_location_id": 2,
  "startTime": "2024-02-07T10:00:00Z",
  "endTime": "2024-02-07T11:45:00Z",
  "notes": "Updated notes - felt really strong today",
  "workoutExercises": []
}
```

---

#### 5. Delete Workout Session

Delete a workout session and all associated data.

**Endpoint**: `DELETE /api/workouts/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The workout session ID |

**Response** (204 No Content):

```
(Empty response body)
```

---

#### 6. Add Exercise to Workout Session

Add an exercise to an active workout session.

**Endpoint**: `POST /api/workouts/{workoutId}/exercises`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `workoutId` | Long | The workout session ID |

**Request Body**:

```json
{
  "exerciseId": 1
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "workout_session_id": 1,
  "exercise": {
    "id": 1,
    "name": "Bench Press",
    "measurementType": "REPS_AND_WEIGHT",
    "isSystemDefined": true,
    "createdAt": "2024-01-10T08:30:00Z"
  },
  "setLogs": []
}
```

---

#### 7. Get Exercises in Workout Session

Retrieve all exercises performed in a workout session.

**Endpoint**: `GET /api/workouts/{workoutId}/exercises`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `workoutId` | Long | The workout session ID |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "workout_session_id": 1,
    "exercise": {
      "id": 1,
      "name": "Bench Press",
      "measurementType": "REPS_AND_WEIGHT",
      "isSystemDefined": true,
      "createdAt": "2024-01-10T08:30:00Z"
    },
    "setLogs": []
  }
]
```

---

#### 8. Remove Exercise from Workout Session

Delete an exercise from a workout session.

**Endpoint**: `DELETE /api/workouts/{workoutId}/exercises/{exerciseId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `workoutId` | Long | The workout session ID |
| `exerciseId` | Long | The workout exercise ID |

**Response** (204 No Content):

```
(Empty response body)
```

---

### Set Logs

Set Logs represent individual sets performed during a workout exercise.

#### 1. Create Set Log

Log a set for an exercise in a workout session.

**Endpoint**: `POST /api/workout-exercises/{workoutExerciseId}/sets`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `workoutExerciseId` | Long | The workout exercise ID |

**Request Body**:

```json
{
  "sets": 1,
  "averageReps": 8,
  "averageWeight": 100.0,
  "averageDurationSeconds": 0,
  "averageDistance": 0,
  "averageCalories": 0
}
```

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "workout_exercise_id": 1,
    "setNumber": 1,
    "completedAt": "2024-02-07T10:15:00Z",
    "weight": 100.0,
    "reps": 8,
    "durationSeconds": 0,
    "distance": 0,
    "calories": 0
  }
]
```

**Notes**:

- `sets` indicates how many sets to create
- Unused metrics should be set to 0 or null
- The endpoint returns an array of created set logs

---

#### 2. Get All Set Logs for Exercise

Retrieve all sets performed for a specific exercise in a workout.

**Endpoint**: `GET /api/workout-exercises/{workoutExerciseId}/sets`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `workoutExerciseId` | Long | The workout exercise ID |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "workout_exercise_id": 1,
    "setNumber": 1,
    "completedAt": "2024-02-07T10:15:00Z",
    "weight": 100.0,
    "reps": 8,
    "durationSeconds": 0,
    "distance": 0,
    "calories": 0
  },
  {
    "id": 2,
    "workout_exercise_id": 1,
    "setNumber": 2,
    "completedAt": "2024-02-07T10:22:00Z",
    "weight": 100.0,
    "reps": 8,
    "durationSeconds": 0,
    "distance": 0,
    "calories": 0
  }
]
```

---

#### 3. Update Set Log

Update a specific set's metrics.

**Endpoint**: `PUT /api/workout-exercises/{workoutExerciseId}/sets/{setLogId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `workoutExerciseId` | Long | The workout exercise ID |
| `setLogId` | Long | The set log ID |

**Request Body**:

```json
{
  "sets": 1,
  "averageReps": 10,
  "averageWeight": 105.0,
  "averageDurationSeconds": 0,
  "averageDistance": 0,
  "averageCalories": 0
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "workout_exercise_id": 1,
  "setNumber": 1,
  "completedAt": "2024-02-07T10:15:00Z",
  "weight": 105.0,
  "reps": 10,
  "durationSeconds": 0,
  "distance": 0,
  "calories": 0
}
```

---

#### 4. Delete Set Log

Delete a specific set from an exercise.

**Endpoint**: `DELETE /api/workout-exercises/{workoutExerciseId}/sets/{setLogId}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `workoutExerciseId` | Long | The workout exercise ID |
| `setLogId` | Long | The set log ID |

**Response** (204 No Content):

```
(Empty response body)
```

---

### Body Metrics

Body Metrics track user's physical measurements over time (weight, height, etc.).

#### 1. Create Body Metric

Log a body metric measurement.

**Endpoint**: `POST /api/body-metrics`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "metricType": "WEIGHT",
  "value": 85.5
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "user_id": 1,
  "metricType": "WEIGHT",
  "value": 85.5,
  "updatedAt": "2024-02-07T10:30:45.123Z",
  "createdAt": "2024-02-07T10:30:45.123Z"
}
```

**Supported MetricTypes**:

- `WEIGHT` - Body weight
- `HEIGHT` - Body height

---

#### 2. Get Body Metrics

Retrieve body metrics with optional filtering.

**Endpoint**: `GET /api/body-metrics?metricType={metricType}&limit={limit}&fromDate={fromDate}&toDate={toDate}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Query Parameters**:
| Parameter | Type | Required | Format | Description |
|---|---|---|---|---|
| `metricType` | String | No | WEIGHT, HEIGHT | Filter by metric type |
| `limit` | Integer | No | Number | Maximum number of results |
| `fromDate` | String | No | ISO 8601 | Start date for filtering |
| `toDate` | String | No | ISO 8601 | End date for filtering |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "user_id": 1,
    "metricType": "WEIGHT",
    "value": 85.5,
    "updatedAt": "2024-02-07T10:30:45.123Z",
    "createdAt": "2024-02-07T10:30:45.123Z"
  },
  {
    "id": 2,
    "user_id": 1,
    "metricType": "WEIGHT",
    "value": 85.2,
    "updatedAt": "2024-02-06T10:30:45.123Z",
    "createdAt": "2024-02-06T10:30:45.123Z"
  }
]
```

**Examples**:

- Get weight history: `GET /api/body-metrics?metricType=WEIGHT`
- Get recent measurements: `GET /api/body-metrics?limit=10`

---

#### 3. Get Latest Body Metrics

Retrieve the most recent measurement for each metric type.

**Endpoint**: `GET /api/body-metrics/latest?metricType={metricType}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Query Parameters**:
| Parameter | Type | Required | Description |
|---|---|---|---|
| `metricType` | String | No | Filter by metric type (WEIGHT, HEIGHT) |

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "user_id": 1,
    "metricType": "WEIGHT",
    "value": 85.5,
    "updatedAt": "2024-02-07T10:30:45.123Z",
    "createdAt": "2024-02-07T10:30:45.123Z"
  },
  {
    "id": 3,
    "user_id": 1,
    "metricType": "HEIGHT",
    "value": 180.5,
    "updatedAt": "2024-01-15T08:30:00Z",
    "createdAt": "2024-01-15T08:30:00Z"
  }
]
```

---

#### 4. Update Body Metric

Update a previously logged body metric.

**Endpoint**: `PUT /api/body-metrics/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The body metric ID |

**Request Body**:

```json
{
  "metricType": "WEIGHT",
  "value": 85.0
}
```

**Response** (200 OK):

```json
{
  "id": 1,
  "user_id": 1,
  "metricType": "WEIGHT",
  "value": 85.0,
  "updatedAt": "2024-02-07T11:00:00Z",
  "createdAt": "2024-02-07T10:30:45.123Z"
}
```

---

#### 5. Delete Body Metric

Delete a body metric entry.

**Endpoint**: `DELETE /api/body-metrics/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The body metric ID |

**Response** (204 No Content):

```
(Empty response body)
```

---

### Locations

Locations represent workout venues where exercises are performed.

#### 1. Get All Locations

Retrieve all workout locations for the authenticated user.

**Endpoint**: `GET /api/locations`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Response** (200 OK):

```json
[
  {
    "id": 1,
    "user_id": 1,
    "name": "Gold's Gym",
    "address": "123 Main St, New York, NY"
  },
  {
    "id": 2,
    "user_id": 1,
    "name": "Home Gym",
    "address": "456 Oak Ave, New York, NY"
  }
]
```

---

#### 2. Create Location

Add a new workout location.

**Endpoint**: `POST /api/locations`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body**:

```json
{
  "name": "Planet Fitness",
  "address": "789 Elm Street, New York, NY"
}
```

**Response** (200 OK):

```json
{
  "id": 3,
  "user_id": 1,
  "name": "Planet Fitness",
  "address": "789 Elm Street, New York, NY"
}
```

**Validation Rules**:

- Name is required and non-empty
- Address is required and non-empty

---

#### 3. Update Location

Update a location's details.

**Endpoint**: `PUT /api/locations/{id}`

**Request Headers**:

```
Authorization: Bearer {token}
Content-Type: application/json
```

**Path Parameters**:
| Parameter | Type | Description |
|---|---|---|
| `id` | Long | The location ID |

**Request Body**:

```json
{
  "name": "Planet Fitness - Updated",
  "address": "789 Elm Street, Apt 5, New York, NY"
}
```

**Response** (200 OK):

```json
{
  "id": 3,
  "user_id": 1,
  "name": "Planet Fitness - Updated",
  "address": "789 Elm Street, Apt 5, New York, NY"
}
```

---

## Quick Reference Examples

### Complete Workflow Example

**1. Sign Up**

```bash
curl -X POST http://localhost:8080/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "securePass123",
    "firstname": "John",
    "lastname": "Doe"
  }'
```

**2. Create User Profile**

```bash
curl -X POST http://localhost:8080/api/me/profile \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "gender": "MALE",
    "height": 180.5,
    "weight": 85.0,
    "experienceLevel": "INTERMEDIATE",
    "goal": "HYPERTROPHY",
    "preferredWeightUnit": "KG",
    "preferredDistanceUnit": "KM"
  }'
```

**3. Create Workout Location**

```bash
curl -X POST http://localhost:8080/api/locations \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Home Gym",
    "address": "123 Main St"
  }'
```

**4. Create Workout Plan**

```bash
curl -X POST http://localhost:8080/api/plans \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Push Pull Legs"
  }'
```

**5. Add Day to Plan**

```bash
curl -X POST http://localhost:8080/api/plans/1/days \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "dayNumber": 1,
    "name": "Push Day"
  }'
```

**6. Add Exercise to Plan Day**

```bash
curl -X POST http://localhost:8080/api/plan-days/1/exercises \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "exerciseId": 1,
    "targetSets": 3,
    "targetReps": 8,
    "targetDurationSeconds": 0,
    "targetDistance": 0,
    "targetCalories": 0
  }'
```

**7. Create Workout Session**

```bash
curl -X POST http://localhost:8080/api/workouts \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "locationId": 1,
    "notes": "Great session",
    "endTime": "2024-02-07T11:30:00Z"
  }'
```

**8. Add Exercise to Workout**

```bash
curl -X POST http://localhost:8080/api/workouts/1/exercises \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "exerciseId": 1
  }'
```

**9. Log Set**

```bash
curl -X POST http://localhost:8080/api/workout-exercises/1/sets \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "sets": 3,
    "averageReps": 8,
    "averageWeight": 100.0,
    "averageDurationSeconds": 0,
    "averageDistance": 0,
    "averageCalories": 0
  }'
```

**10. Log Body Metric**

```bash
curl -X POST http://localhost:8080/api/body-metrics \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "metricType": "WEIGHT",
    "value": 85.5
  }'
```

---

## Relationship Diagram

```
User (1)
├── UserProfile (1)
├── Locations (Many)
├── WorkoutPlans (Many)
│   └── PlanDays (Many)
│       └── PlanExercises (Many)
│           └── Exercise (1)
├── WorkoutSessions (Many)
│   └── WorkoutExercises (Many)
│       ├── Exercise (1)
│       └── SetLogs (Many)
├── BodyMetrics (Many)
└── Exercises - UserDefined (Many)
```

---

## Important Notes

### Authentication

- Tokens are required for all endpoints except `/auth/login` and `/auth/signup`
- Include token in `Authorization: Bearer {token}` header
- Tokens are generated using JWT and should be stored securely on the client

### Data Validation

- All date-time values are in ISO 8601 format
- Timestamps are UTC-based
- Empty/unused numeric fields should be set to 0 or omitted

### Data Ownership

- Users can only access and modify their own data
- Accessing another user's resources will return 401 Unauthorized

### Workout Session Flow

1. Create a workout session
2. Add exercises to the session
3. For each exercise, log sets with performance metrics
4. Close the session by updating end time

### Exercise Measurement Types

Choose the appropriate `MeasurementType` based on how the exercise is tracked:

- **REPS**: Push-ups, pull-ups (count reps only)
- **TIME**: Plank holds, cardio (time only)
- **REPS_AND_TIME**: Circuit training
- **TIME_AND_WEIGHT**: Kettlebell swings
- **REPS_AND_WEIGHT**: Bench press, squats (weight + reps)
- **DISTANCE_AND_TIME**: Running, cycling
- **CALORIES_AND_TIME**: Cardio machines

---

## Rate Limiting & Performance

- No explicit rate limiting is currently enforced
- Database queries are optimized for typical use cases
- For bulk operations, batch requests when possible

---

## Database Schema Overview

**Key Tables**:

- `users` - User accounts
- `user_profiles` - User fitness profiles
- `exercises` - Exercise definitions
- `workout_plans` - User's workout plans
- `plan_days` - Days within workout plans
- `plan_exercises` - Exercises assigned to plan days
- `workout_sessions` - Individual workout instances
- `workout_exercises` - Exercises within a session
- `set_logs` - Individual sets performed
- `body_metrics` - Body measurements
- `locations` - Workout venues

---

## Support & Troubleshooting

### Common Issues

**"auth not found"**

- Make sure to include `Authorization: Bearer {token}` header
- Verify token is valid and not expired
- Re-login if necessary

**"Could not find workouts within the constraints"**

- Check date format (must be ISO 8601)
- Ensure startDate is before endDate
- Verify data exists within the date range

**"User with email exists"**

- The email is already registered
- Use login endpoint to access existing account

---

## Version History

- **v1.0** (Current) - Initial API release
  - User authentication
  - Workout plan management
  - Workout session tracking
  - Exercise library
  - Body metrics tracking
  - Location management

---

**Last Updated**: February 7, 2026
**API Status**: Production Ready

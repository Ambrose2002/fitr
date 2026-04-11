package com.example.fitrbackend.service;

import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.fitrbackend.dto.CreateWorkoutExerciseReqeust;
import com.example.fitrbackend.dto.WorkoutExerciseResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.model.Exercise;
import com.example.fitrbackend.model.MeasurementType;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.model.WorkoutSession;
import com.example.fitrbackend.repository.ExerciseRepository;
import com.example.fitrbackend.repository.LocationRepository;
import com.example.fitrbackend.repository.SetLogRepository;
import com.example.fitrbackend.repository.UserRepository;
import com.example.fitrbackend.repository.WorkoutExerciseRepository;
import com.example.fitrbackend.repository.WorkoutSessionRepository;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class WorkoutSessionServiceTest {

    @Mock
    private WorkoutSessionRepository workoutSessionRepository;

    @Mock
    private UserRepository userRepository;

    @Mock
    private LocationRepository locationRepository;

    @Mock
    private WorkoutExerciseRepository workoutExerciseRepository;

    @Mock
    private SetLogRepository setLogRepository;

    @Mock
    private ExerciseRepository exerciseRepository;

    private WorkoutSessionService workoutSessionService;

    @BeforeEach
    void setUp() {
        workoutSessionService = new WorkoutSessionService(
                workoutSessionRepository,
                userRepository,
                locationRepository,
                workoutExerciseRepository,
                setLogRepository,
                exerciseRepository);
    }

    @Test
    void createWorkoutExerciseRejectsForeignCustomExercise() {
        String email = "owner@example.com";
        long workoutId = 10L;
        long exerciseId = 99L;

        User owner = new User("Owner", "User", email, "pw");
        User foreignOwner = new User("Foreign", "User", "foreign@example.com", "pw");
        WorkoutSession workoutSession = new WorkoutSession(owner, Instant.now(), null, "", null);
        Exercise foreignExercise = new Exercise("Foreign Lift", MeasurementType.REPS, foreignOwner);

        CreateWorkoutExerciseReqeust request = mock(CreateWorkoutExerciseReqeust.class);
        when(request.getExerciseId()).thenReturn(exerciseId);
        when(userRepository.findByEmail(email)).thenReturn(owner);
        when(workoutSessionRepository.findById(workoutId)).thenReturn(Optional.of(workoutSession));
        when(exerciseRepository.findById(exerciseId)).thenReturn(Optional.of(foreignExercise));

        DataCreationFailedException exception = assertThrows(
                DataCreationFailedException.class,
                () -> workoutSessionService.createWorkoutExercise(email, workoutId, request));

        org.junit.jupiter.api.Assertions.assertEquals("user does not own exercise", exception.getMessage());
        verify(workoutExerciseRepository, never()).findByWorkoutSessionIdAndExerciseId(anyLong(), anyLong());
        verify(workoutExerciseRepository, never()).save(any());
    }

    @Test
    void createWorkoutExerciseAllowsOwnedCustomExercise() {
        String email = "owner@example.com";
        long workoutId = 10L;
        long exerciseId = 44L;

        User owner = new User("Owner", "User", email, "pw");
        WorkoutSession workoutSession = new WorkoutSession(owner, Instant.now(), null, "", null);
        Exercise ownedCustomExercise = new Exercise("Owner Lift", MeasurementType.REPS_AND_WEIGHT, owner);

        CreateWorkoutExerciseReqeust request = mock(CreateWorkoutExerciseReqeust.class);
        when(request.getExerciseId()).thenReturn(exerciseId);
        when(userRepository.findByEmail(email)).thenReturn(owner);
        when(workoutSessionRepository.findById(workoutId)).thenReturn(Optional.of(workoutSession));
        when(exerciseRepository.findById(exerciseId)).thenReturn(Optional.of(ownedCustomExercise));
        when(workoutExerciseRepository.findByWorkoutSessionIdAndExerciseId(workoutId, exerciseId)).thenReturn(List.of());
        when(workoutExerciseRepository.save(any())).thenAnswer(invocation -> invocation.getArgument(0));
        when(setLogRepository.findByWorkoutExerciseId(anyLong())).thenReturn(List.of());

        WorkoutExerciseResponse response = workoutSessionService.createWorkoutExercise(email, workoutId, request);

        assertNotNull(response);
        verify(workoutExerciseRepository).save(any());
    }
}

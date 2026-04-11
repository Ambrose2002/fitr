package com.example.fitrbackend.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.example.fitrbackend.dto.CreateExerciseRequest;
import com.example.fitrbackend.dto.ExerciseResponse;
import com.example.fitrbackend.exception.DataCreationFailedException;
import com.example.fitrbackend.model.Exercise;
import com.example.fitrbackend.model.MeasurementType;
import com.example.fitrbackend.model.User;
import com.example.fitrbackend.repository.ExerciseRepository;
import com.example.fitrbackend.repository.UserRepository;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class ExerciseServiceTest {

    @Mock
    private ExerciseRepository exerciseRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private ExerciseService exerciseService;

    @Test
    void updateExerciseRejectsSystemExercise() {
        Exercise systemExercise = new Exercise("Bench Press", MeasurementType.REPS, null);
        when(exerciseRepository.findById(5L)).thenReturn(Optional.of(systemExercise));

        CreateExerciseRequest request = mock(CreateExerciseRequest.class);

        DataCreationFailedException exception = assertThrows(
                DataCreationFailedException.class,
                () -> exerciseService.updateExercise("owner@example.com", request, 5L));

        assertEquals("system exercises cannot be updated", exception.getMessage());
        verify(exerciseRepository, never()).save(any());
    }

    @Test
    void updateExerciseRejectsForeignCustomExercise() {
        User foreignUser = new User("Foreign", "Owner", "foreign@example.com", "pw");
        Exercise foreignExercise = new Exercise("Foreign Lift", MeasurementType.REPS, foreignUser);
        when(exerciseRepository.findById(7L)).thenReturn(Optional.of(foreignExercise));

        CreateExerciseRequest request = mock(CreateExerciseRequest.class);

        DataCreationFailedException exception = assertThrows(
                DataCreationFailedException.class,
                () -> exerciseService.updateExercise("owner@example.com", request, 7L));

        assertEquals("user does not own exercise", exception.getMessage());
        verify(exerciseRepository, never()).save(any());
    }

    @Test
    void updateExerciseAllowsOwnedCustomExercise() {
        User owner = new User("Owner", "User", "owner@example.com", "pw");
        Exercise customExercise = new Exercise("Old Name", MeasurementType.REPS, owner);
        when(exerciseRepository.findById(9L)).thenReturn(Optional.of(customExercise));
        when(exerciseRepository.save(customExercise)).thenReturn(customExercise);

        CreateExerciseRequest request = mock(CreateExerciseRequest.class);
        when(request.getName()).thenReturn("New Name");
        when(request.getMeasurementType()).thenReturn(MeasurementType.DISTANCE_AND_TIME);

        ExerciseResponse response = exerciseService.updateExercise("owner@example.com", request, 9L);

        assertEquals("New Name", response.getName());
        assertEquals(MeasurementType.DISTANCE_AND_TIME, response.getMeasurementType());
        verify(exerciseRepository).save(customExercise);
    }
}

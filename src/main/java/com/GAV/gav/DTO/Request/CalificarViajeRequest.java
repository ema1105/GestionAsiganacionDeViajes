package com.GAV.gav.DTO.Request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;

// Calificación enviada por el cliente al conductor al finalizar un viaje.
// Puntuación obligatoria 1-5. El comentario es opcional pero limitado a 500 chars.
@Data
public class CalificarViajeRequest {

    @NotNull(message = "La puntuación es obligatoria")
    @Min(value = 1, message = "La puntuación mínima es 1")
    @Max(value = 5, message = "La puntuación máxima es 5")
    private Integer puntuacion;

    @Size(max = 500, message = "El comentario no puede superar 500 caracteres")
    private String comentario;
}

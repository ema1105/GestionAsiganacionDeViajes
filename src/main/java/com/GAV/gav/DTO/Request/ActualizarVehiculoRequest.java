package com.GAV.gav.DTO.Request;

import jakarta.validation.constraints.Min;
import lombok.Data;

// Actualización parcial: todos los campos opcionales.
@Data
public class ActualizarVehiculoRequest {

    private String marca;
    private String modelo;
    private String placa;

    @Min(value = 1, message = "La capacidad máxima debe ser al menos 1")
    private Integer capacidadMaxima;

    private Long categoriaVehiculoId;
}

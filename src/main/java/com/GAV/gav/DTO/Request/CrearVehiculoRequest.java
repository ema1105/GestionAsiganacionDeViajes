package com.GAV.gav.DTO.Request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CrearVehiculoRequest {

    @NotBlank(message = "La marca es obligatoria")
    private String marca;

    @NotBlank(message = "El modelo es obligatorio")
    private String modelo;

    @NotBlank(message = "La placa es obligatoria")
    private String placa;

    @Min(value = 1, message = "La capacidad máxima debe ser al menos 1")
    private int capacidadMaxima;

    @NotNull(message = "La categoría del vehículo es obligatoria")
    private Long categoriaVehiculoId;
}

package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class VehiculoResponse {

    private Long id;
    private String marca;
    private String modelo;
    private String placa;
    private int capacidadMaxima;
    private Long categoriaId;
    private String categoriaNombre;

    // Si el vehículo está actualmente asignado a un conductor, se incluyen sus datos básicos.
    private Long conductorAsignadoId;
    private String conductorAsignadoNombre;
}

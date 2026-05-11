package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Conductor disponible cerca del cliente. Incluye distancia precalculada
// (en km, Haversine) y datos básicos para mostrar en el mapa.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ConductorCercanoResponse {

    private Long conductorId;
    private String nombreCompleto;
    private BigDecimal lat;
    private BigDecimal lng;
    private double distanciaKm;
    private LocalDateTime ultimaActualizacion;

    private String vehiculoMarca;
    private String vehiculoModelo;
    private String vehiculoPlaca;
    private int capacidadMaxima;
}

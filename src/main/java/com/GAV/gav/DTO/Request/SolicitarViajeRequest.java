package com.GAV.gav.DTO.Request;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

// El frontend (React + JS Maps Directions Service) calcula la ruta y manda
// distancia y duración estimadas. El backend valida los rangos y calcula el precio.
// Este enfoque evita consumir Distance Matrix API desde el backend (costo adicional).
@Data
public class SolicitarViajeRequest {

    @Min(value = 1, message = "Debe haber al menos 1 pasajero")
    private int cantidadPasajeros;

    @NotNull(message = "La latitud de origen es obligatoria")
    private BigDecimal origenLat;

    @NotNull(message = "La longitud de origen es obligatoria")
    private BigDecimal origenLng;

    @NotNull(message = "La latitud de destino es obligatoria")
    private BigDecimal destinoLat;

    @NotNull(message = "La longitud de destino es obligatoria")
    private BigDecimal destinoLng;

    // Distancia en km calculada por el frontend con Google Maps Directions Service.
    // Se valida un rango razonable para evitar manipulación cliente.
    @NotNull(message = "La distancia (km) es obligatoria")
    @DecimalMin(value = "0.1", message = "La distancia debe ser al menos 0.1 km")
    private BigDecimal distanciaKm;

    // Duración estimada en minutos calculada por el frontend con Google Maps Directions Service.
    @Min(value = 1, message = "La duración estimada debe ser al menos 1 minuto")
    private int duracionMin;
}

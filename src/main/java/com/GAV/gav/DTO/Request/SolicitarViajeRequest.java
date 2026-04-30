package com.GAV.gav.DTO.Request;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

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
}

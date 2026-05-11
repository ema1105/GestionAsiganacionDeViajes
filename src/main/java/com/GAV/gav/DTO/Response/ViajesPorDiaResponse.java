package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

// Una fila por día con la cantidad de viajes solicitados ese día.
// Para el dashboard: el frontend grafica fecha vs cantidad.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ViajesPorDiaResponse {

    private LocalDate fecha;
    private long cantidad;
}

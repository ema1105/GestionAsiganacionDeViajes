package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Resumen de ganancias en un periodo. Útil para el dashboard de admin
// y para alimentar reportes Power BI.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class  GananciasResponse {

    private String periodo;          // ej: "2026-05-09" o "2026-05"
    private LocalDateTime desde;
    private LocalDateTime hasta;
    private BigDecimal total;        // suma de precioCalculado de viajes FINALIZADOS
    private long cantidadViajes;     // cantidad de viajes contabilizados
}

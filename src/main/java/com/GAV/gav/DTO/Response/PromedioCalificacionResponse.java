package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

// Resumen de calificaciones recibidas: promedio + total de calificaciones contabilizadas.
// El frontend lo usa para mostrar el rating en el header del perfil del conductor.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PromedioCalificacionResponse {

    private Double promedio;             // null si no hay calificaciones aún
    private long totalCalificaciones;
}

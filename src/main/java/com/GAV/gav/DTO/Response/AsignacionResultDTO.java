package com.GAV.gav.DTO.Response;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

// Mapea exactamente el JSON devuelto por el microservicio Python de optimización (ILP):
// {
//   "asignaciones": [{"conductor_id": 1, "viaje_id": 10}],
//   "viajes_cubiertos": 1,
//   "total_conductores_disponibles": 3,
//   "total_viajes_pendientes": 2,
//   "status": "Optimal"
// }
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class AsignacionResultDTO {

    private List<AssignmentDTO> asignaciones;

    @JsonProperty("viajes_cubiertos")
    private int viajesCubiertos;

    @JsonProperty("total_conductores_disponibles")
    private int totalConductoresDisponibles;

    @JsonProperty("total_viajes_pendientes")
    private int totalViajesPendientes;

    private String status;

    // Par conductor -> viaje de la asignación óptima.
    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class AssignmentDTO {

        @JsonProperty("conductor_id")
        private Long conductorId;

        @JsonProperty("viaje_id")
        private Long viajeId;
    }
}

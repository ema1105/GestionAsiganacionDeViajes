package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Calificacion;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

// DTO aplanado de una calificación. Evita serialización recursiva del entity.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CalificacionResponse {

    private Long id;
    private Long viajeId;
    private Long calificadorId;
    private String calificadorNombre;
    private Long calificadoId;
    private String calificadoNombre;
    private Calificacion.TipoCalificacion tipoCalificacion;
    private Integer puntuacion;
    private String comentario;
    private LocalDateTime fechaCalificacion;
}

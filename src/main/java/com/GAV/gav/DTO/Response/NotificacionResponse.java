package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Notificacion;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

// DTO de respuesta para notificaciones consumidas por el frontend.
// Aplana las referencias para evitar serialización recursiva (Usuario, Viaje).
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class NotificacionResponse {

    private Long id;
    private Long usuarioId;
    private Long viajeId;
    private Notificacion.TipoNotificacion tipo;
    private String mensaje;
    private Boolean leida;
    private LocalDateTime fechaCreacion;
}

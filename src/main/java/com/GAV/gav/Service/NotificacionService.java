package com.GAV.gav.Service;

import com.GAV.gav.DTO.Response.NotificacionResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.Notificacion;
import com.GAV.gav.Model.Usuario;
import com.GAV.gav.Model.Viaje;
import com.GAV.gav.Repository.NotificacionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

// Centraliza la creación, consulta y marcado-como-leída de notificaciones.
// Modelo de entrega: REST polling — el frontend consulta /api/notificaciones/no-leidas periódicamente.
@Service
@RequiredArgsConstructor
public class NotificacionService {

    private final NotificacionRepository notificacionRepository;

    // Crea y persiste una notificación dirigida a un usuario específico (cliente o conductor).
    // El campo `viaje` es opcional — algunos eventos del sistema podrían no estar ligados a un viaje.
    @Transactional
    public Notificacion crear(Usuario destinatario, Viaje viaje,
                              Notificacion.TipoNotificacion tipo, String mensaje) {
        Notificacion n = new Notificacion();
        n.setUsuario(destinatario);
        n.setViaje(viaje);
        n.setTipoNotificacion(tipo);
        n.setMensaje(mensaje);
        n.setLeida(false);
        n.setFechaCreacion(LocalDateTime.now());
        return notificacionRepository.save(n);
    }

    public List<NotificacionResponse> listarTodas(Long usuarioId) {
        return notificacionRepository.findByUsuarioIdOrderByFechaCreacionDesc(usuarioId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public List<NotificacionResponse> listarNoLeidas(Long usuarioId) {
        return notificacionRepository
                .findByUsuarioIdAndLeidaFalseOrderByFechaCreacionDesc(usuarioId)
                .stream()
                .map(this::mapToResponse)
                .toList();
    }

    public long contarNoLeidas(Long usuarioId) {
        return notificacionRepository.countByUsuarioIdAndLeidaFalse(usuarioId);
    }

    // Marca una notificación como leída. Solo el destinatario original puede marcarla.
    @Transactional
    public NotificacionResponse marcarComoLeida(Long notificacionId, Long usuarioId) {
        Notificacion n = notificacionRepository.findById(notificacionId)
                .orElseThrow(() -> new BusinessException(
                        "Notificación no encontrada: " + notificacionId, HttpStatus.NOT_FOUND));

        if (n.getUsuario() == null || !n.getUsuario().getId().equals(usuarioId)) {
            throw new BusinessException(
                    "No puedes marcar como leída una notificación de otro usuario.",
                    HttpStatus.FORBIDDEN);
        }

        n.setLeida(true);
        notificacionRepository.save(n);
        return mapToResponse(n);
    }

    // Marca TODAS las notificaciones no leídas del usuario como leídas.
    @Transactional
    public int marcarTodasComoLeidas(Long usuarioId) {
        List<Notificacion> noLeidas = notificacionRepository
                .findByUsuarioIdAndLeidaFalseOrderByFechaCreacionDesc(usuarioId);
        noLeidas.forEach(n -> n.setLeida(true));
        notificacionRepository.saveAll(noLeidas);
        return noLeidas.size();
    }

    private NotificacionResponse mapToResponse(Notificacion n) {
        return NotificacionResponse.builder()
                .id(n.getId())
                .usuarioId(n.getUsuario() != null ? n.getUsuario().getId() : null)
                .viajeId(n.getViaje() != null ? n.getViaje().getId() : null)
                .tipo(n.getTipoNotificacion())
                .mensaje(n.getMensaje())
                .leida(n.getLeida())
                .fechaCreacion(n.getFechaCreacion())
                .build();
    }
}

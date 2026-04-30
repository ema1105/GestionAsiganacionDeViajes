package com.GAV.gav.Service;

import com.GAV.gav.DTO.Response.ViajeResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

// Lógica de negocio exclusiva del rol CONDUCTOR.
// El conductor puede: responder una solicitud (aceptar/rechazar) y finalizar un viaje activo.
// Cuando acepta → sale del pool FIFO (disponibilidad=false).
// Cuando finaliza → vuelve al pool FIFO (disponibilidad=true, fechaDisponibleDesde=now()).
@Service
@RequiredArgsConstructor
public class ConductorService {

    private final ConductorRepository conductorRepository;
    private final ViajeConductorRepository viajeConductorRepository;
    private final ViajeRepository viajeRepository;
    private final ViajeService viajeService;

    // El conductor responde la solicitud de un viaje.
    // Si acepta: el viaje queda asignado a él y sale del pool FIFO.
    // Si rechaza: se registra el rechazo y se busca el siguiente en la cola FIFO.
    @Transactional
    public ViajeResponse responderSolicitud(Long viajeId, Long conductorId, boolean aceptar) {
        // Solo se puede responder a una solicitud en estado PENDIENTE
        ViajeConductor solicitud = viajeConductorRepository
                .findByViajeIdAndConductorUsuarioId(viajeId, conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Solicitud no encontrada para el viaje " + viajeId
                                + " y conductor " + conductorId,
                        HttpStatus.NOT_FOUND));

        if (solicitud.getEstado() != ViajeConductor.EstadoSolicitud.PENDIENTE) {
            throw new BusinessException(
                    "La solicitud ya fue procesada (estado: " + solicitud.getEstado() + ")",
                    HttpStatus.CONFLICT);
        }

        Viaje viaje = solicitud.getViaje();
        solicitud.setFechaRespuesta(LocalDateTime.now());

        if (aceptar) {
            return procesarAceptacion(solicitud, viaje);
        } else {
            return procesarRechazo(solicitud, viaje);
        }
    }

    // Acepta el viaje: actualiza el estado del viaje, asigna el conductor y lo saca del pool FIFO
    private ViajeResponse procesarAceptacion(ViajeConductor solicitud, Viaje viaje) {
        solicitud.setEstado(ViajeConductor.EstadoSolicitud.ACEPTADO);
        viajeConductorRepository.save(solicitud);

        Conductor conductor = solicitud.getConductor();

        // Asignar el conductor al viaje y avanzar el estado
        viaje.setConductor(conductor.getUsuario());
        viaje.setAutomovil(conductor.getAutomovil());
        viaje.setEstadoViaje(Viaje.EstadoViaje.ACEPTADO);
        viaje.setFechaInicio(LocalDateTime.now());
        viajeRepository.save(viaje);

        // El conductor sale del pool FIFO: no disponible y sin timestamp de cola
        conductor.setDisponibilidad(false);
        conductor.setFechaDisponibleDesde(null);
        conductorRepository.save(conductor);

        // TODO: notificar al cliente que su conductor fue asignado (WebSocket / Notificacion)
        // notificacionService.crear(viaje.getCliente(), viaje, TipoNotificacion.CONDUTOR_ASIGNADO);

        return viajeService.mapToViajeResponse(viaje);
    }

    // Rechaza el viaje: registra el rechazo y avanza al siguiente conductor en la cola FIFO
    private ViajeResponse procesarRechazo(ViajeConductor solicitud, Viaje viaje) {
        solicitud.setEstado(ViajeConductor.EstadoSolicitud.RECHAZADO);
        viajeConductorRepository.save(solicitud);

        // El conductor rechazó pero sigue disponible para otros viajes (no cambia su disponibilidad)
        // El FIFO lo excluirá solo para ESTE viaje específico (por el filtro de excluidos en el query)

        // Buscar el siguiente conductor en la cola FIFO para este viaje
        viaje.setEstadoViaje(Viaje.EstadoViaje.BUSCANDO_CONDUCTOR);
        viajeRepository.save(viaje);
        viajeService.asignarSiguienteConductorFIFO(viaje);

        return viajeService.mapToViajeResponse(viaje);
    }

    // El conductor marca el viaje como finalizado.
    // Esto lo devuelve al pool FIFO con una nueva fechaDisponibleDesde.
    @Transactional
    public ViajeResponse finalizarViaje(Long viajeId, Long conductorId) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));

        // Validar que este conductor sea el asignado al viaje
        if (viaje.getConductor() == null || !viaje.getConductor().getId().equals(conductorId)) {
            throw new BusinessException(
                    "El conductor " + conductorId + " no está asignado a este viaje.",
                    HttpStatus.FORBIDDEN);
        }

        if (viaje.getEstadoViaje() != Viaje.EstadoViaje.EN_CURSO
                && viaje.getEstadoViaje() != Viaje.EstadoViaje.ACEPTADO
                && viaje.getEstadoViaje() != Viaje.EstadoViaje.EN_CAMINO) {
            throw new BusinessException(
                    "El viaje no puede finalizarse en estado: " + viaje.getEstadoViaje(),
                    HttpStatus.CONFLICT);
        }

        viaje.setEstadoViaje(Viaje.EstadoViaje.FINALIZADO);
        viaje.setFechaFinalizacion(LocalDateTime.now());
        viajeRepository.save(viaje);

        // El conductor finaliza → vuelve al pool FIFO con timestamp de ahora
        // Quien lleve más tiempo esperando después de él tendrá mayor prioridad
        Conductor conductor = conductorRepository.findByUsuarioId(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));

        conductor.setDisponibilidad(true);
        conductor.setFechaDisponibleDesde(LocalDateTime.now());
        conductorRepository.save(conductor);

        // TODO: notificar al cliente que el viaje finalizó (WebSocket / Notificacion)

        return viajeService.mapToViajeResponse(viaje);
    }

    // Devuelve el historial de solicitudes de un conductor (aceptadas, rechazadas, expiradas)
    public List<ViajeConductor> obtenerHistorialSolicitudes(Long conductorId) {
        return viajeConductorRepository.findByConductorUsuarioId(conductorId);
    }
}

package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.SolicitarViajeRequest;
import com.GAV.gav.DTO.Response.ViajeResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

// Gestiona el ciclo de vida de los viajes y contiene la lógica central del algoritmo FIFO.
//
// FLUJO FIFO:
//   1. Cliente solicita viaje → Viaje creado en estado SOLICITADO
//   2. Sistema busca conductores disponibles ordenados por fechaDisponibleDesde ASC (FIFO)
//   3. Se filtra por capacidad del vehículo y se excluyen conductores que ya rechazaron/expiraron
//   4. Se crea ViajeConductor(PENDIENTE) para el primer conductor de la cola
//   5. Conductor tiene SEGUNDOS_EXPIRACION para responder
//   6. Si no responde → scheduler marca como EXPIRADO → siguiente en cola FIFO
//   7. Si acepta → viaje queda en estado ACEPTADO, conductor sale del pool
//   8. Si no hay conductores → viaje queda en BUSCANDO_CONDUCTOR hasta que uno se conecte
@Service
@RequiredArgsConstructor
public class ViajeService {

    // Tiempo máximo (segundos) para que un conductor responda una solicitud antes de expirar
    private static final int SEGUNDOS_EXPIRACION = 30;

    private final ViajeRepository viajeRepository;
    private final UsuarioRepository usuarioRepository;
    private final ConductorRepository conductorRepository;
    private final ViajeConductorRepository viajeConductorRepository;

    // El cliente solicita un viaje. Se crea el registro y se dispara la asignación FIFO inmediatamente.
    @Transactional
    public ViajeResponse solicitarViaje(SolicitarViajeRequest request, Long clienteId) {
        Usuario cliente = usuarioRepository.findById(clienteId)
                .orElseThrow(() -> new BusinessException(
                        "Cliente no encontrado: " + clienteId, HttpStatus.NOT_FOUND));

        Viaje viaje = new Viaje();
        viaje.setCliente(cliente);
        viaje.setCantidadPasajeros(request.getCantidadPasajeros());
        viaje.setOrigenLat(request.getOrigenLat());
        viaje.setOrigenLng(request.getOrigenLng());
        viaje.setDestinoLat(request.getDestinoLat());
        viaje.setDestinoLng(request.getDestinoLng());
        viaje.setEstadoViaje(Viaje.EstadoViaje.SOLICITADO);
        viaje.setFechaSolicitud(LocalDateTime.now());
        Viaje viajeGuardado = viajeRepository.save(viaje);

        // Disparar la asignación FIFO en la misma transacción
        asignarPrimerConductorFIFO(viajeGuardado);

        return mapToViajeResponse(viajeRepository.findById(viajeGuardado.getId()).orElse(viajeGuardado));
    }

    // Primera asignación: no hay conductores excluidos aún, solo filtrar por capacidad
    private void asignarPrimerConductorFIFO(Viaje viaje) {
        viaje.setEstadoViaje(Viaje.EstadoViaje.BUSCANDO_CONDUCTOR);
        viajeRepository.save(viaje);

        List<Conductor> candidatos = conductorRepository
                .findPrimerConductorFIFO(viaje.getCantidadPasajeros());

        if (candidatos.isEmpty()) {
            // No hay conductores disponibles; el viaje queda en BUSCANDO_CONDUCTOR.
            // El scheduler o una llamada futura a asignarSiguienteConductorFIFO lo retomará.
            return;
        }

        crearSolicitudPendiente(viaje, candidatos.get(0));
    }

    // Asignación de siguiente conductor en FIFO tras rechazo o expiración.
    // Excluye conductores que ya rechazaron o expiraron para este viaje específico.
    @Transactional
    public void asignarSiguienteConductorFIFO(Viaje viaje) {
        List<ViajeConductor.EstadoSolicitud> excluidos = List.of(
                ViajeConductor.EstadoSolicitud.RECHAZADO,
                ViajeConductor.EstadoSolicitud.EXPIRADO
        );

        List<Conductor> candidatos = conductorRepository
                .findSiguienteConductorFIFO(viaje.getCantidadPasajeros(), viaje.getId(), excluidos);

        if (candidatos.isEmpty()) {
            // Cola agotada: nadie disponible que no haya rechazado/expirado ya
            viaje.setEstadoViaje(Viaje.EstadoViaje.BUSCANDO_CONDUCTOR);
            viajeRepository.save(viaje);
            return;
        }

        crearSolicitudPendiente(viaje, candidatos.get(0));
    }

    // Crea el registro ViajeConductor(PENDIENTE) y notifica al conductor.
    // La notificación real (WebSocket) se conectará aquí cuando se integre el NotificacionService.
    private void crearSolicitudPendiente(Viaje viaje, Conductor conductor) {
        LocalDateTime ahora = LocalDateTime.now();
        ViajeConductor solicitud = new ViajeConductor(
                viaje,
                conductor,
                ViajeConductor.EstadoSolicitud.PENDIENTE,
                ahora,
                ahora.plusSeconds(SEGUNDOS_EXPIRACION)
        );
        viajeConductorRepository.save(solicitud);

        // TODO: emitir evento WebSocket al conductor para que vea la solicitud en su app
        // webSocketService.notificarConductor(conductor.getUsuarioId(), viaje);
    }

    // Scheduler que corre cada 10 segundos para detectar solicitudes que expiraron sin respuesta.
    // Marca como EXPIRADO y avanza al siguiente conductor en la cola FIFO automáticamente.
    @Scheduled(fixedDelay = 10_000)
    @Transactional
    public void verificarSolicitudesExpiradas() {
        List<ViajeConductor> expiradas = viajeConductorRepository
                .findSolicitudesExpiradas(LocalDateTime.now());

        for (ViajeConductor solicitud : expiradas) {
            solicitud.setEstado(ViajeConductor.EstadoSolicitud.EXPIRADO);
            solicitud.setFechaRespuesta(LocalDateTime.now());
            viajeConductorRepository.save(solicitud);

            Viaje viaje = solicitud.getViaje();
            // Solo avanzar si el viaje aún está buscando conductor
            if (viaje.getEstadoViaje() == Viaje.EstadoViaje.BUSCANDO_CONDUCTOR
                    || viaje.getEstadoViaje() == Viaje.EstadoViaje.SOLICITADO) {
                asignarSiguienteConductorFIFO(viaje);
            }
        }
    }

    // Consultas de viajes
    public List<ViajeResponse> obtenerViajesCliente(Long clienteId) {
        return viajeRepository.findByClienteId(clienteId)
                .stream()
                .map(this::mapToViajeResponse)
                .toList();
    }

    public List<ViajeResponse> obtenerViajesPendientes() {
        return viajeRepository.findViajesPendientes()
                .stream()
                .map(this::mapToViajeResponse)
                .toList();
    }

    public ViajeResponse obtenerViajePorId(Long viajeId) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));
        return mapToViajeResponse(viaje);
    }

    // Mapea la entidad Viaje al DTO de respuesta aplanando las referencias
    public ViajeResponse mapToViajeResponse(Viaje v) {
        ViajeResponse.ViajeResponseBuilder builder = ViajeResponse.builder()
                .id(v.getId())
                .cantidadPasajeros(v.getCantidadPasajeros())
                .origenLat(v.getOrigenLat())
                .origenLng(v.getOrigenLng())
                .destinoLat(v.getDestinoLat())
                .destinoLng(v.getDestinoLng())
                .estadoViaje(v.getEstadoViaje())
                .precioCalculado(v.getPrecioCalculado())
                .fechaSolicitud(v.getFechaSolicitud())
                .fechaInicio(v.getFechaInicio())
                .fechaFinalizacion(v.getFechaFinalizacion());

        if (v.getCliente() != null) {
            builder.clienteId(v.getCliente().getId())
                   .clienteNombre(v.getCliente().getNombreCompleto());
        }

        if (v.getConductor() != null) {
            builder.conductorId(v.getConductor().getId())
                   .conductorNombre(v.getConductor().getNombreCompleto());
        }

        return builder.build();
    }
}

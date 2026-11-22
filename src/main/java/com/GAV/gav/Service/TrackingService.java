package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.RegistrarUbicacionRequest;
import com.GAV.gav.DTO.Response.ConductorCercanoResponse;
import com.GAV.gav.DTO.Response.PuntoSeguimientoResponse;
import com.GAV.gav.DTO.Response.UbicacionResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

// Gestiona tracking GPS:
//   - Heartbeat de ubicación de cada conductor disponible (tabla ubicacion_conductor)
//   - Puntos de seguimiento durante un viaje activo (tabla seguimiento_viaje)
//   - Cálculo de conductores cercanos a un punto usando Haversine
@Service
@RequiredArgsConstructor
public class TrackingService {

    private static final double RADIO_TIERRA_KM = 6371.0;

    private final UbicacionConductorRepository ubicacionRepository;
    private final SeguimientoViajeRepository seguimientoRepository;
    private final ConductorRepository conductorRepository;
    private final ViajeRepository viajeRepository;

    // ========================================================================
    // HEARTBEAT DE UBICACIÓN DEL CONDUCTOR
    // ========================================================================

    @Transactional
    public UbicacionResponse registrarUbicacion(Long conductorId, RegistrarUbicacionRequest req) {
        Conductor conductor = conductorRepository.findByUsuarioId(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));

        UbicacionConductor u = new UbicacionConductor();
        u.setConductor(conductor);
        u.setLat(req.getLat());
        u.setLng(req.getLng());
        u.setFecha(LocalDateTime.now());
        UbicacionConductor guardada = ubicacionRepository.save(u);

        return UbicacionResponse.builder()
                .id(guardada.getId())
                .conductorId(conductorId)
                .lat(guardada.getLat())
                .lng(guardada.getLng())
                .fecha(guardada.getFecha())
                .build();
    }

    // ========================================================================
    // CONDUCTORES CERCANOS (Haversine en Java sobre el resultado del repo)
    // ========================================================================

    public List<ConductorCercanoResponse> conductoresCercanos(double lat, double lng,
                                                               double radioKm) {
        List<UbicacionConductor> ultimas = ubicacionRepository.findUltimaUbicacionDeDisponibles();

        return ultimas.stream()
                .map(u -> {
                    double dist = haversineKm(lat, lng,
                            u.getLat().doubleValue(), u.getLng().doubleValue());
                    return toConductorCercano(u, dist);
                })
                .filter(c -> c.getDistanciaKm() <= radioKm)
                .sorted(Comparator.comparingDouble(ConductorCercanoResponse::getDistanciaKm))
                .toList();
    }

    private ConductorCercanoResponse toConductorCercano(UbicacionConductor u, double distancia) {
        Conductor c = u.getConductor();
        Usuario usuario = c != null ? c.getUsuario() : null;
        Automovil auto = c != null ? c.getAutomovil() : null;

        return ConductorCercanoResponse.builder()
                .conductorId(c != null ? c.getUsuarioId() : null)
                .nombreCompleto(usuario != null ? usuario.getNombreCompleto() : null)
                .lat(u.getLat())
                .lng(u.getLng())
                .distanciaKm(redondear2(distancia))
                .ultimaActualizacion(u.getFecha())
                .vehiculoMarca(auto != null ? auto.getMarca() : null)
                .vehiculoModelo(auto != null ? auto.getModelo() : null)
                .vehiculoPlaca(auto != null ? auto.getPlaca() : null)
                .capacidadMaxima(auto != null ? auto.getCapacidadMaxima() : 0)
                .build();
    }

    // Fórmula de Haversine: distancia entre dos puntos en una esfera (la Tierra).
    private double haversineKm(double lat1, double lng1, double lat2, double lng2) {
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return RADIO_TIERRA_KM * c;
    }

    private double redondear2(double valor) {
        return Math.round(valor * 100.0) / 100.0;
    }

    // ========================================================================
    // SEGUIMIENTO DEL VIAJE (punto a punto)
    // ========================================================================

    // El conductor reporta un punto GPS durante un viaje activo (ACEPTADO|EN_CAMINO|EN_CURSO).
    @Transactional
    public PuntoSeguimientoResponse registrarPuntoSeguimiento(Long viajeId, Long conductorId,
                                                               RegistrarUbicacionRequest req) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));

        if (viaje.getConductor() == null
                || !viaje.getConductor().getId().equals(conductorId)) {
            throw new BusinessException(
                    "El conductor " + conductorId + " no está asignado a este viaje.",
                    HttpStatus.FORBIDDEN);
        }

        Viaje.EstadoViaje estado = viaje.getEstadoViaje();
        if (estado != Viaje.EstadoViaje.ACEPTADO
                && estado != Viaje.EstadoViaje.EN_CAMINO
                && estado != Viaje.EstadoViaje.EN_CURSO) {
            throw new BusinessException(
                    "Solo se puede agregar seguimiento a un viaje activo. Estado: " + estado,
                    HttpStatus.CONFLICT);
        }

        SeguimientoViaje punto = new SeguimientoViaje();
        punto.setViaje(viaje);
        punto.setLat(req.getLat());
        punto.setLng(req.getLng());
        punto.setFecha(LocalDateTime.now());
        SeguimientoViaje guardado = seguimientoRepository.save(punto);

        return toPuntoResponse(guardado);
    }

    // Último punto registrado del viaje (real-time view).
    // Si esCliente=true valida que el cliente sea el solicitante.
    // Si esConductor=true valida que el conductor sea el asignado.
    // Si esAdmin=true se omite la validación de ownership.
    public PuntoSeguimientoResponse ultimoPunto(Long viajeId, Long usuarioId,
                                                 boolean esCliente, boolean esConductor) {
        Viaje viaje = obtenerViajeYValidar(viajeId, usuarioId, esCliente, esConductor);
        return seguimientoRepository.findTopByViajeIdOrderByFechaDesc(viaje.getId())
                .map(this::toPuntoResponse)
                .orElse(null);
    }

    // Recorrido completo del viaje. Validaciones de ownership equivalentes.
    public List<PuntoSeguimientoResponse> recorridoCompleto(Long viajeId, Long usuarioId,
                                                              boolean esCliente, boolean esConductor) {
        Viaje viaje = obtenerViajeYValidar(viajeId, usuarioId, esCliente, esConductor);
        return seguimientoRepository.findByViajeIdOrderByFechaAsc(viaje.getId())
                .stream()
                .map(this::toPuntoResponse)
                .toList();
    }

    // ========================================================================
    // Helpers
    // ========================================================================

    private Viaje obtenerViajeYValidar(Long viajeId, Long usuarioId,
                                        boolean esCliente, boolean esConductor) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));

        if (esCliente) {
            if (viaje.getCliente() == null || !viaje.getCliente().getId().equals(usuarioId)) {
                throw new BusinessException(
                        "El cliente " + usuarioId + " no es el solicitante de este viaje.",
                        HttpStatus.FORBIDDEN);
            }
        } else if (esConductor) {
            if (viaje.getConductor() == null || !viaje.getConductor().getId().equals(usuarioId)) {
                throw new BusinessException(
                        "El conductor " + usuarioId + " no está asignado a este viaje.",
                        HttpStatus.FORBIDDEN);
            }
        }
        // Si es admin, se omite la validación.
        return viaje;
    }

    private PuntoSeguimientoResponse toPuntoResponse(SeguimientoViaje s) {
        return PuntoSeguimientoResponse.builder()
                .id(s.getId())
                .viajeId(s.getViaje() != null ? s.getViaje().getId() : null)
                .lat(s.getLat())
                .lng(s.getLng())
                .fecha(s.getFecha())
                .build();
    }
}

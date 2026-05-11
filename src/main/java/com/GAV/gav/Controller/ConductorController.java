package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Request.ActualizarPerfilConductorRequest;
import com.GAV.gav.DTO.Request.CalificarViajeRequest;
import com.GAV.gav.DTO.Request.RegistrarUbicacionRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Model.Viaje;
import com.GAV.gav.Model.ViajeConductor;
import com.GAV.gav.Security.AuthenticatedUserProvider;
import com.GAV.gav.Service.ConductorService;
import com.GAV.gav.Service.TrackingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

// Endpoints exclusivos del rol CONDUCTOR.
// Spring Security ya restringe /api/conductor/** a ROLE_CONDUCTOR.
@RestController
@RequestMapping("/api/conductor")
@RequiredArgsConstructor
public class ConductorController {

    private final ConductorService conductorService;
    private final TrackingService trackingService;
    private final AuthenticatedUserProvider authenticatedUserProvider;

    // ====================================================================
    // SOLICITUDES Y MÁQUINA DE ESTADOS DEL VIAJE
    // ====================================================================

    @GetMapping("/solicitudes/pendiente")
    public ResponseEntity<SolicitudPendienteDTO> obtenerSolicitudPendiente() {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        ViajeConductor solicitud = conductorService.obtenerSolicitudPendiente(conductorId);
        if (solicitud == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(SolicitudPendienteDTO.from(solicitud));
    }

    @PostMapping("/viajes/{viajeId}/responder")
    public ResponseEntity<ViajeResponse> responderSolicitud(
            @PathVariable Long viajeId,
            @RequestParam("aceptar") boolean aceptar) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(
                conductorService.responderSolicitud(viajeId, conductorId, aceptar));
    }

    @PostMapping("/viajes/{viajeId}/en-camino")
    public ResponseEntity<ViajeResponse> marcarEnCamino(@PathVariable Long viajeId) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.marcarEnCamino(viajeId, conductorId));
    }

    @PostMapping("/viajes/{viajeId}/iniciar")
    public ResponseEntity<ViajeResponse> iniciarViaje(@PathVariable Long viajeId) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.iniciarViaje(viajeId, conductorId));
    }

    @PostMapping("/viajes/{viajeId}/finalizar")
    public ResponseEntity<ViajeResponse> finalizarViaje(@PathVariable Long viajeId) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.finalizarViaje(viajeId, conductorId));
    }

    @PostMapping("/viajes/{viajeId}/cancelar")
    public ResponseEntity<ViajeResponse> cancelarViaje(
            @PathVariable Long viajeId,
            @RequestBody(required = false) Map<String, String> body) {
        String motivo = body != null ? body.get("motivo") : null;
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.cancelarViaje(viajeId, conductorId, motivo));
    }

    // ====================================================================
    // PERFIL — el conductor ve y modifica su propio perfil
    // ====================================================================

    @GetMapping("/perfil")
    public ResponseEntity<PerfilConductorResponse> obtenerPerfil() {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.obtenerPerfil(conductorId));
    }

    @PutMapping("/perfil")
    public ResponseEntity<PerfilConductorResponse> actualizarPerfil(
            @Valid @RequestBody ActualizarPerfilConductorRequest request) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.actualizarPerfil(conductorId, request));
    }

    // ====================================================================
    // MAPA — viaje activo y detalle expandido (con datos del cliente)
    // ====================================================================

    @GetMapping("/viaje-activo")
    public ResponseEntity<ViajeResponse> obtenerViajeActivo() {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        ViajeResponse activo = conductorService.obtenerViajeActivo(conductorId);
        if (activo == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(activo);
    }

    @GetMapping("/viajes/{viajeId}/detalle")
    public ResponseEntity<ViajeDetalleConductorResponse> obtenerDetalleViaje(
            @PathVariable Long viajeId) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.obtenerDetalleViaje(viajeId, conductorId));
    }

    // ====================================================================
    // HISTORIAL PAGINADO
    // ====================================================================

    // Historial de viajes del conductor.
    // Sin params: trae todos los estados (ACEPTADO, EN_CAMINO, EN_CURSO, FINALIZADO, CANCELADO).
    // Con ?estado=FINALIZADO trae solo Completados; con EN_CAMINO trae solo esos; etc.
    @GetMapping("/viajes")
    public ResponseEntity<PageResponse<ViajeResponse>> historialViajes(
            @RequestParam(required = false) Viaje.EstadoViaje estado,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(
                conductorService.historialViajes(conductorId, estado, desde, hasta, page, size));
    }

    // Atajo para "En proceso" (ACEPTADO|EN_CAMINO|EN_CURSO). Útil para el panel principal del conductor.
    @GetMapping("/viajes/en-proceso")
    public ResponseEntity<PageResponse<ViajeResponse>> viajesEnProceso(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.historialEnProceso(conductorId, page, size));
    }

    // Historial de solicitudes (ofertas) recibidas. Útil para el tab "Pendientes" si filtra
    // ?estado=PENDIENTE, o para ver el log completo de rechazos/expirados/aceptados.
    @GetMapping("/solicitudes")
    public ResponseEntity<PageResponse<SolicitudResponse>> historialSolicitudes(
            @RequestParam(required = false) ViajeConductor.EstadoSolicitud estado,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(
                conductorService.historialSolicitudes(conductorId, estado, page, size));
    }

    // ====================================================================
    // ESTADÍSTICAS DEL CONDUCTOR
    // ====================================================================

    @GetMapping("/estadisticas/ganancias/dia")
    public ResponseEntity<GananciasResponse> gananciasDelDia(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.gananciasDelDia(conductorId, fecha));
    }

    @GetMapping("/estadisticas/ganancias/mes")
    public ResponseEntity<GananciasResponse> gananciasDelMes(
            @RequestParam int anio,
            @RequestParam int mes) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.gananciasDelMes(conductorId, anio, mes));
    }

    @GetMapping("/estadisticas/viajes/dia")
    public ResponseEntity<Map<String, Object>> viajesDelDia(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        long cantidad = conductorService.viajesDelDia(conductorId, fecha);
        return ResponseEntity.ok(Map.of("fecha", fecha, "cantidad", cantidad));
    }

    @GetMapping("/estadisticas/viajes/mes")
    public ResponseEntity<Map<String, Object>> viajesDelMes(
            @RequestParam int anio,
            @RequestParam int mes) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        long cantidad = conductorService.viajesDelMes(conductorId, anio, mes);
        return ResponseEntity.ok(Map.of(
                "periodo", String.format("%04d-%02d", anio, mes),
                "cantidad", cantidad));
    }

    // ====================================================================
    // CALIFICAR AL CLIENTE (CONDUCTOR → CLIENTE)
    // ====================================================================

    @PostMapping("/viajes/{viajeId}/calificar-cliente")
    public ResponseEntity<CalificacionResponse> calificarCliente(
            @PathVariable Long viajeId,
            @Valid @RequestBody CalificarViajeRequest request) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(conductorService.calificarCliente(viajeId, conductorId, request));
    }

    // ====================================================================
    // CALIFICACIONES RECIBIDAS (visualización)
    // ====================================================================

    @GetMapping("/calificaciones")
    public ResponseEntity<PageResponse<CalificacionResponse>> calificacionesRecibidas(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(
                conductorService.obtenerCalificacionesRecibidas(conductorId, page, size));
    }

    @GetMapping("/calificaciones/promedio")
    public ResponseEntity<PromedioCalificacionResponse> promedioCalificaciones() {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(conductorService.obtenerPromedioCalificaciones(conductorId));
    }

    // ====================================================================
    // TRACKING GPS — ubicación del conductor y seguimiento durante el viaje
    // ====================================================================

    // Heartbeat de ubicación. El conductor lo envía periódicamente (cada N segundos)
    // mientras tiene la app activa, independiente de si está en un viaje.
    @PostMapping("/ubicacion")
    public ResponseEntity<UbicacionResponse> registrarUbicacion(
            @Valid @RequestBody RegistrarUbicacionRequest request) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(trackingService.registrarUbicacion(conductorId, request));
    }

    // Punto GPS durante un viaje activo (ACEPTADO|EN_CAMINO|EN_CURSO).
    @PostMapping("/viajes/{viajeId}/seguimiento")
    public ResponseEntity<PuntoSeguimientoResponse> registrarPuntoSeguimiento(
            @PathVariable Long viajeId,
            @Valid @RequestBody RegistrarUbicacionRequest request) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(trackingService.registrarPuntoSeguimiento(viajeId, conductorId, request));
    }

    // Recorrido completo del viaje (el conductor ve los puntos que él mismo reportó).
    @GetMapping("/viajes/{viajeId}/seguimiento")
    public ResponseEntity<List<PuntoSeguimientoResponse>> recorridoCompleto(
            @PathVariable Long viajeId) {
        Long conductorId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(trackingService.recorridoCompleto(
                viajeId, conductorId, false, true));
    }

    // ====================================================================
    // DTO inline para la solicitud entrante (compatibilidad con polling existente)
    // ====================================================================

    public record SolicitudPendienteDTO(
            Long solicitudId,
            Long viajeId,
            Long clienteId,
            String clienteNombre,
            int cantidadPasajeros,
            java.math.BigDecimal origenLat,
            java.math.BigDecimal origenLng,
            java.math.BigDecimal destinoLat,
            java.math.BigDecimal destinoLng,
            java.math.BigDecimal precioCalculado,
            java.time.LocalDateTime fechaOferta,
            java.time.LocalDateTime fechaExpiracion
    ) {
        static SolicitudPendienteDTO from(ViajeConductor vc) {
            var v = vc.getViaje();
            return new SolicitudPendienteDTO(
                    vc.getId(),
                    v.getId(),
                    v.getCliente() != null ? v.getCliente().getId() : null,
                    v.getCliente() != null ? v.getCliente().getNombreCompleto() : null,
                    v.getCantidadPasajeros(),
                    v.getOrigenLat(),
                    v.getOrigenLng(),
                    v.getDestinoLat(),
                    v.getDestinoLng(),
                    v.getPrecioCalculado(),
                    vc.getFechaOferta(),
                    vc.getFechaExpiracion()
            );
        }
    }
}

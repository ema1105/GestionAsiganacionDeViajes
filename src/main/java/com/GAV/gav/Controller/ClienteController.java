package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Request.ActualizarPerfilClienteRequest;
import com.GAV.gav.DTO.Request.CalificarViajeRequest;
import com.GAV.gav.DTO.Request.SolicitarViajeRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Model.Viaje;
import com.GAV.gav.Security.AuthenticatedUserProvider;
import com.GAV.gav.Service.ClienteService;
import com.GAV.gav.Service.TrackingService;
import com.GAV.gav.Service.ViajeService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

// Endpoints exclusivos del rol CLIENTE.
// Spring Security ya restringe /api/cliente/** a ROLE_CLIENTE.
@RestController
@RequestMapping("/api/cliente")
@RequiredArgsConstructor
public class ClienteController {

    private final ViajeService viajeService;
    private final ClienteService clienteService;
    private final TrackingService trackingService;
    private final AuthenticatedUserProvider authenticatedUserProvider;

    // ====================================================================
    // VIAJES — solicitar, cancelar, consultar (lo existente)
    // ====================================================================

    @PostMapping("/viajes")
    public ResponseEntity<ViajeResponse> solicitarViaje(
            @Valid @RequestBody SolicitarViajeRequest request) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(viajeService.solicitarViaje(request, clienteId));
    }

    // Listado simple (legacy). Para historial filtrado y paginado usar GET /viajes.
    @GetMapping("/viajes/mis")
    public ResponseEntity<List<ViajeResponse>> obtenerMisViajes() {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(viajeService.obtenerViajesCliente(clienteId));
    }

    @GetMapping("/viajes/{viajeId}")
    public ResponseEntity<ViajeResponse> obtenerViaje(@PathVariable Long viajeId) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        ViajeResponse v = viajeService.obtenerViajePorId(viajeId);
        if (v.getClienteId() == null || !v.getClienteId().equals(clienteId)) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }
        return ResponseEntity.ok(v);
    }

    @PostMapping("/viajes/{viajeId}/cancelar")
    public ResponseEntity<ViajeResponse> cancelarViaje(
            @PathVariable Long viajeId,
            @RequestBody(required = false) Map<String, String> body) {
        String motivo = body != null ? body.get("motivo") : null;
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(
                viajeService.cancelarPorCliente(viajeId, clienteId, motivo));
    }

    // ====================================================================
    // PERFIL
    // ====================================================================

    @GetMapping("/perfil")
    public ResponseEntity<PerfilClienteResponse> obtenerPerfil() {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(clienteService.obtenerPerfil(clienteId));
    }

    @PutMapping("/perfil")
    public ResponseEntity<PerfilClienteResponse> actualizarPerfil(
            @Valid @RequestBody ActualizarPerfilClienteRequest request) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(clienteService.actualizarPerfil(clienteId, request));
    }

    // ====================================================================
    // MAPA — viaje activo y detalle expandido (con datos del conductor)
    // ====================================================================

    @GetMapping("/viaje-activo")
    public ResponseEntity<ViajeResponse> obtenerViajeActivo() {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        ViajeResponse activo = clienteService.obtenerViajeActivo(clienteId);
        if (activo == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(activo);
    }

    @GetMapping("/viajes/{viajeId}/detalle")
    public ResponseEntity<ViajeDetalleClienteResponse> obtenerDetalleViaje(
            @PathVariable Long viajeId) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(clienteService.obtenerDetalleViaje(viajeId, clienteId));
    }

    // ====================================================================
    // HISTORIAL PAGINADO CON FILTROS
    // ====================================================================

    // Estados visibles para el cliente:
    //   - SOLICITADO / BUSCANDO_CONDUCTOR  → "Pendientes"
    //   - ACEPTADO / EN_CAMINO / EN_CURSO  → "En proceso"
    //   - FINALIZADO                       → "Completados" / "Finalizados"
    //   - CANCELADO                        → "Cancelados"
    @GetMapping("/viajes")
    public ResponseEntity<PageResponse<ViajeResponse>> historialViajes(
            @RequestParam(required = false) Viaje.EstadoViaje estado,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(
                clienteService.historialViajes(clienteId, estado, desde, hasta, page, size));
    }

    // ====================================================================
    // CALIFICACIÓN AL CONDUCTOR
    // ====================================================================

    @PostMapping("/viajes/{viajeId}/calificar")
    public ResponseEntity<CalificacionResponse> calificarConductor(
            @PathVariable Long viajeId,
            @Valid @RequestBody CalificarViajeRequest request) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(clienteService.calificarConductor(viajeId, clienteId, request));
    }

    // ====================================================================
    // CALIFICACIONES RECIBIDAS (CONDUCTOR → CLIENTE)
    // ====================================================================

    @GetMapping("/calificaciones")
    public ResponseEntity<PageResponse<CalificacionResponse>> calificacionesRecibidas(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(
                clienteService.obtenerCalificacionesRecibidas(clienteId, page, size));
    }

    @GetMapping("/calificaciones/promedio")
    public ResponseEntity<PromedioCalificacionResponse> promedioCalificaciones() {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(clienteService.obtenerPromedioCalificaciones(clienteId));
    }

    // ====================================================================
    // TRACKING GPS — conductores cercanos y seguimiento del viaje
    // ====================================================================

    // Conductores disponibles más cercanos al punto (lat, lng), dentro del radio.
    // Ordenados por distancia ascendente. Útil para mostrar el mapa antes de solicitar viaje.
    @GetMapping("/conductores-cercanos")
    public ResponseEntity<List<ConductorCercanoResponse>> conductoresCercanos(
            @RequestParam double lat,
            @RequestParam double lng,
            @RequestParam(defaultValue = "5.0") double radioKm) {
        return ResponseEntity.ok(trackingService.conductoresCercanos(lat, lng, radioKm));
    }

    // Último punto registrado del viaje (real-time, para el mapa del cliente).
    @GetMapping("/viajes/{viajeId}/seguimiento/ultima")
    public ResponseEntity<PuntoSeguimientoResponse> ultimoPuntoSeguimiento(
            @PathVariable Long viajeId) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        PuntoSeguimientoResponse punto = trackingService.ultimoPunto(
                viajeId, clienteId, true, false);
        if (punto == null) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(punto);
    }

    // Recorrido completo del viaje (útil al finalizar para mostrar la ruta total).
    @GetMapping("/viajes/{viajeId}/seguimiento")
    public ResponseEntity<List<PuntoSeguimientoResponse>> recorridoCompleto(
            @PathVariable Long viajeId) {
        Long clienteId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(trackingService.recorridoCompleto(
                viajeId, clienteId, true, false));
    }
}

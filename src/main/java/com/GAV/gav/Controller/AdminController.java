package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Request.ActualizarConductorRequest;
import com.GAV.gav.DTO.Request.ActualizarVehiculoRequest;
import com.GAV.gav.DTO.Request.CrearVehiculoRequest;
import com.GAV.gav.DTO.Request.RegisterConductorRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.Viaje;
import com.GAV.gav.Service.AdminService;
import com.GAV.gav.Service.TrackingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

// Endpoints exclusivos del rol ADMIN.
// Spring Security ya restringe /api/admin/** a ROLE_ADMIN en SecurityConfig.
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;
    private final TrackingService trackingService;

    // ====================================================================
    // CONDUCTORES
    // ====================================================================

    @PostMapping("/conductores")
    public ResponseEntity<ConductorResponse> registrarConductor(
            @Valid @RequestBody RegisterConductorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(adminService.registrarConductor(request));
    }

    @GetMapping("/conductores")
    public ResponseEntity<List<ConductorResponse>> listarConductores(
            @RequestParam(required = false) Boolean disponibilidad,
            @RequestParam(required = false) Conductor.TipoLicencia tipoLicencia,
            @RequestParam(name = "incluirInactivos", defaultValue = "false") boolean incluirInactivos) {
        return ResponseEntity.ok(
                adminService.listarConductores(disponibilidad, tipoLicencia, incluirInactivos));
    }

    @GetMapping("/conductores/{id}")
    public ResponseEntity<ConductorResponse> obtenerConductor(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.obtenerConductor(id));
    }

    @PutMapping("/conductores/{id}")
    public ResponseEntity<ConductorResponse> actualizarConductor(
            @PathVariable Long id,
            @Valid @RequestBody ActualizarConductorRequest request) {
        return ResponseEntity.ok(adminService.actualizarConductor(id, request));
    }

    @PostMapping("/conductores/{id}/deshabilitar")
    public ResponseEntity<ConductorResponse> deshabilitarConductor(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.deshabilitarConductor(id));
    }

    @PostMapping("/conductores/{id}/habilitar")
    public ResponseEntity<ConductorResponse> habilitarConductor(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.habilitarConductor(id));
    }

    @DeleteMapping("/conductores/{id}")
    public ResponseEntity<Void> eliminarConductor(@PathVariable Long id) {
        adminService.eliminarConductor(id);
        return ResponseEntity.noContent().build();
    }

    // ====================================================================
    // VEHÍCULOS
    // ====================================================================

    @PostMapping("/vehiculos")
    public ResponseEntity<VehiculoResponse> crearVehiculo(
            @Valid @RequestBody CrearVehiculoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(adminService.crearVehiculo(request));
    }

    @GetMapping("/vehiculos")
    public ResponseEntity<List<VehiculoResponse>> listarVehiculos() {
        return ResponseEntity.ok(adminService.listarVehiculos());
    }

    @GetMapping("/vehiculos/{id}")
    public ResponseEntity<VehiculoResponse> obtenerVehiculo(@PathVariable Long id) {
        return ResponseEntity.ok(adminService.obtenerVehiculo(id));
    }

    @PutMapping("/vehiculos/{id}")
    public ResponseEntity<VehiculoResponse> actualizarVehiculo(
            @PathVariable Long id,
            @Valid @RequestBody ActualizarVehiculoRequest request) {
        return ResponseEntity.ok(adminService.actualizarVehiculo(id, request));
    }

    @DeleteMapping("/vehiculos/{id}")
    public ResponseEntity<Void> eliminarVehiculo(@PathVariable Long id) {
        adminService.eliminarVehiculo(id);
        return ResponseEntity.noContent().build();
    }

    // ====================================================================
    // ASOCIACIÓN CONDUCTOR ↔ VEHÍCULO
    // ====================================================================

    @PostMapping("/conductores/{conductorId}/vehiculo/{vehiculoId}")
    public ResponseEntity<ConductorResponse> asociarVehiculo(
            @PathVariable Long conductorId,
            @PathVariable Long vehiculoId) {
        return ResponseEntity.ok(adminService.asociarVehiculo(conductorId, vehiculoId));
    }

    @DeleteMapping("/conductores/{conductorId}/vehiculo")
    public ResponseEntity<ConductorResponse> desasociarVehiculo(
            @PathVariable Long conductorId) {
        return ResponseEntity.ok(adminService.desasociarVehiculo(conductorId));
    }

    // ====================================================================
    // HISTORIAL DE VIAJES (paginado con filtros)
    // ====================================================================

    @GetMapping("/viajes")
    public ResponseEntity<PageResponse<ViajeResponse>> listarViajes(
            @RequestParam(required = false) Viaje.EstadoViaje estado,
            @RequestParam(required = false) Long clienteId,
            @RequestParam(required = false) Long conductorId,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime desde,
            @RequestParam(required = false)
                @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime hasta,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ResponseEntity.ok(adminService.listarViajes(
                estado, clienteId, conductorId, desde, hasta, page, size));
    }

    // ====================================================================
    // ESTADÍSTICAS — ganancias y viajes
    // ====================================================================

    @GetMapping("/estadisticas/ganancias/dia")
    public ResponseEntity<GananciasResponse> gananciasDelDia(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        return ResponseEntity.ok(adminService.gananciasDelDia(fecha));
    }

    @GetMapping("/estadisticas/ganancias/mes")
    public ResponseEntity<GananciasResponse> gananciasDelMes(
            @RequestParam int anio,
            @RequestParam int mes) {
        return ResponseEntity.ok(adminService.gananciasDelMes(anio, mes));
    }

    @GetMapping("/estadisticas/viajes/dia")
    public ResponseEntity<java.util.Map<String, Object>> viajesDelDia(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fecha) {
        long count = adminService.viajesDelDia(fecha);
        return ResponseEntity.ok(java.util.Map.of("fecha", fecha, "cantidad", count));
    }

    @GetMapping("/estadisticas/viajes/por-dia")
    public ResponseEntity<List<ViajesPorDiaResponse>> viajesPorDia(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate desde,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate hasta) {
        return ResponseEntity.ok(adminService.viajesPorDia(desde, hasta));
    }

    // ====================================================================
    // TRACKING — vista admin del recorrido completo de cualquier viaje
    // ====================================================================

    @GetMapping("/viajes/{viajeId}/seguimiento")
    public ResponseEntity<List<PuntoSeguimientoResponse>> recorridoCompleto(
            @PathVariable Long viajeId) {
        // Admin omite la validación de ownership (3er y 4to args = false)
        return ResponseEntity.ok(trackingService.recorridoCompleto(
                viajeId, null, false, false));
    }
}

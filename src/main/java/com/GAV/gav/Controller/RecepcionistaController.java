package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Request.RegisterClienteRequest;
import com.GAV.gav.DTO.Request.SolicitarViajeRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.Viaje;
import com.GAV.gav.Service.RecepcionistaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

// Endpoints exclusivos del rol RECEPCIONISTA.
// Restricción a /api/recepcionista/** la aplica SecurityConfig (ROLE_RECEPCIONISTA).
@RestController
@RequestMapping("/api/recepcionista")
@RequiredArgsConstructor
public class RecepcionistaController {

    private final RecepcionistaService recepcionistaService;

    // ====================================================================
    // CHECK-IN DE CLIENTES (huéspedes)
    // ====================================================================

    @PostMapping("/clientes")
    public ResponseEntity<UsuarioResponse> registrarCliente(
            @Valid @RequestBody RegisterClienteRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(recepcionistaService.registrarCliente(request));
    }

    // ====================================================================
    // SOLICITAR VIAJE EN NOMBRE DE UN CLIENTE
    // ====================================================================

    @PostMapping("/clientes/{clienteId}/viajes")
    public ResponseEntity<ViajeResponse> solicitarViajeParaCliente(
            @PathVariable Long clienteId,
            @Valid @RequestBody SolicitarViajeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(recepcionistaService.solicitarViajeParaCliente(clienteId, request));
    }

    // ====================================================================
    // VISTA READ-ONLY: viajes con filtros y paginación
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
        return ResponseEntity.ok(recepcionistaService.listarViajes(
                estado, clienteId, conductorId, desde, hasta, page, size));
    }

    @GetMapping("/viajes/{viajeId}")
    public ResponseEntity<ViajeResponse> obtenerViaje(@PathVariable Long viajeId) {
        return ResponseEntity.ok(recepcionistaService.obtenerViaje(viajeId));
    }

    // ====================================================================
    // VISTA READ-ONLY: conductores
    // ====================================================================

    @GetMapping("/conductores")
    public ResponseEntity<List<ConductorResponse>> listarConductores(
            @RequestParam(required = false) Boolean disponibilidad,
            @RequestParam(required = false) Conductor.TipoLicencia tipoLicencia) {
        return ResponseEntity.ok(
                recepcionistaService.listarConductores(disponibilidad, tipoLicencia));
    }
}

package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Viaje;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Vista expandida del viaje para el conductor: incluye datos de contacto
// del cliente (teléfono, email) necesarios para que el conductor pueda
// comunicarse durante el viaje. Solo el conductor asignado al viaje puede consultarla.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ViajeDetalleConductorResponse {

    private Long id;
    private Viaje.EstadoViaje estadoViaje;
    private int cantidadPasajeros;

    private BigDecimal origenLat;
    private BigDecimal origenLng;
    private BigDecimal destinoLat;
    private BigDecimal destinoLng;

    private BigDecimal precioCalculado;

    private LocalDateTime fechaSolicitud;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFinalizacion;

    // --- Datos completos del cliente para contacto durante el viaje ---
    private Long clienteId;
    private String clienteNombre;
    private String clienteApellidos;
    private String clienteTelefono;
    private String clienteEmail;
}

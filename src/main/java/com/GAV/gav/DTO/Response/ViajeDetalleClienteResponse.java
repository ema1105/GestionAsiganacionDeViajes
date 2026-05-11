package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Viaje;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Vista expandida del viaje para el cliente: incluye los datos del conductor
// asignado (nombre completo, teléfono, vehículo) para contacto durante el viaje.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ViajeDetalleClienteResponse {

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

    // --- Datos del conductor asignado (null si todavía no se asignó) ---
    private Long conductorId;
    private String conductorNombre;
    private String conductorApellidos;
    private String conductorTelefono;

    // --- Datos del vehículo asignado ---
    private String vehiculoMarca;
    private String vehiculoModelo;
    private String vehiculoPlaca;
    private String vehiculoCategoria;
}

package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.ViajeConductor;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// DTO aplanado de una solicitud (oferta) recibida por un conductor.
// Para listados paginados de historial de solicitudes.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class SolicitudResponse {

    private Long solicitudId;
    private Long viajeId;
    private ViajeConductor.EstadoSolicitud estado;

    private Long clienteId;
    private String clienteNombre;

    private int cantidadPasajeros;
    private BigDecimal origenLat;
    private BigDecimal origenLng;
    private BigDecimal destinoLat;
    private BigDecimal destinoLng;
    private BigDecimal precioCalculado;

    private LocalDateTime fechaOferta;
    private LocalDateTime fechaRespuesta;
    private LocalDateTime fechaExpiracion;
}

package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Viaje;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ViajeResponse {

    private Long id;
    private int cantidadPasajeros;

    private BigDecimal origenLat;
    private BigDecimal origenLng;
    private BigDecimal destinoLat;
    private BigDecimal destinoLng;

    private Viaje.EstadoViaje estadoViaje;

    // Solo datos esenciales del cliente y conductor para evitar referencias circulares
    private Long clienteId;
    private String clienteNombre;

    private Long conductorId;
    private String conductorNombre;

    private BigDecimal precioCalculado;

    private LocalDateTime fechaSolicitud;
    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFinalizacion;
}

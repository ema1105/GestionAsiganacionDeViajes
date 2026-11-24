package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Viaje;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Un conductor conectado en el mapa "Flota en vivo" del admin.
// estado: DISPONIBLE (sin viaje en curso) o EN_VIAJE (ACEPTADO, EN_CAMINO o EN_CURSO).
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class FlotaUbicacionResponse {

    private Long conductorId;
    private String nombre;
    private String vehiculo;
    private String placa;

    private BigDecimal lat;
    private BigDecimal lng;
    private LocalDateTime ultimaSenal;

    private String estado;

    // Solo si estado = EN_VIAJE
    private Long viajeId;
    private Viaje.EstadoViaje viajeEstado;
    private String origenNombre;
    private String destinoNombre;
    private BigDecimal origenLat;
    private BigDecimal origenLng;
    private BigDecimal destinoLat;
    private BigDecimal destinoLng;
}

package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Conductor;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ConductorResponse {

    private Long usuarioId;
    private String nombreCompleto;
    private String apellidosCompletos;
    private String email;
    private String telefono;
    private String licencia;
    private Conductor.TipoLicencia tipoLicencia;
    private Boolean disponibilidad;

    // Datos básicos del vehículo aplanados para evitar referencias circulares en la respuesta JSON
    private String marcaVehiculo;
    private String modeloVehiculo;
    private String placaVehiculo;
    private int capacidadMaxima;
    private String categoriaVehiculo;
}

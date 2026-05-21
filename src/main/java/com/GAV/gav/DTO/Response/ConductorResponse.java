package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.Usuario;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ConductorResponse {

    private Long usuarioId;
    private String nombreCompleto;
    private String apellidosCompletos;
    // NUEVOS: necesarios para que el formulario de edición del admin cargue
    // todos los campos con los valores reales del conductor.
    private Date fechaNacimiento;
    private Usuario.TipoDocumento tipoDocumento;
    private String numeroDocumento;
    private String email;
    private String telefono;
    private String licencia;
    private Conductor.TipoLicencia tipoLicencia;
    private Boolean disponibilidad;
    private Boolean activo;

    // Datos básicos del vehículo aplanados para evitar referencias circulares en la respuesta JSON.
    // automovilId se incluye para que el front pueda referenciar/cambiar el vehículo asignado.
    private Long automovilId;
    private String marcaVehiculo;
    private String modeloVehiculo;
    private String placaVehiculo;
    private int capacidadMaxima;
    private String categoriaVehiculo;
}

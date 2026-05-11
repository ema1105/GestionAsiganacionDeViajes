package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.Usuario;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

// Vista de perfil que ve el propio conductor. Incluye los datos sensibles
// como lectura — el frontend los muestra como campos deshabilitados.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PerfilConductorResponse {

    private Long usuarioId;

    // --- Datos sensibles (solo lectura) ---
    private String nombreCompleto;
    private String apellidosCompletos;
    private Date fechaNacimiento;
    private String nombreUsuario;
    private Usuario.TipoDocumento tipoDocumento;
    private String numeroDocumento;
    private String licencia;
    private Conductor.TipoLicencia tipoLicencia;

    // --- Datos modificables ---
    private Usuario.Genero genero;
    private String telefono;
    private String email;

    // --- Estado del conductor ---
    private Boolean disponibilidad;
    private Boolean activo;

    // --- Vehículo asignado (solo lectura para el conductor; el admin lo gestiona) ---
    private String marcaVehiculo;
    private String modeloVehiculo;
    private String placaVehiculo;
    private int capacidadMaxima;
    private String categoriaVehiculo;
}

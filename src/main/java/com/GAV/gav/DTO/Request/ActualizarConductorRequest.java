package com.GAV.gav.DTO.Request;

import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.Usuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.Date;

// Actualización parcial del conductor: todos los campos son opcionales.
// Si un campo viene null, no se modifica. Esto permite que el frontend
// haga PATCH-style sin tener que enviar el objeto completo.
@Data
public class ActualizarConductorRequest {

    // --- Datos de Usuario ---
    private String nombreCompleto;
    private String apellidosCompletos;
    private Date fechaNacimiento;
    private String telefono;

    @Email(message = "El correo no tiene un formato válido")
    private String email;

    private Usuario.TipoDocumento tipoDocumento;
    private String numeroDocumento;

    @Size(min = 6, message = "La contraseña debe tener mínimo 6 caracteres")
    private String contrasena;

    // --- Datos de Conductor ---
    private String licencia;
    private Conductor.TipoLicencia tipoLicencia;
}

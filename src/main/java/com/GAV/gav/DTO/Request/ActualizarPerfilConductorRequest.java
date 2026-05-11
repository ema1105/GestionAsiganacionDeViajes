package com.GAV.gav.DTO.Request;

import com.GAV.gav.Model.Usuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Data;

// Actualización de perfil que el propio conductor puede hacer.
// Solo se aceptan campos modificables. Datos sensibles (nombre, apellidos,
// documento, licencia, tipoLicencia, fechaNacimiento) están bloqueados y deben
// solicitarse al admin. Todos los campos son opcionales — null = no modificar.
@Data
public class ActualizarPerfilConductorRequest {

    private Usuario.Genero genero;

    private String telefono;

    @Email(message = "El correo no tiene un formato válido")
    private String email;

    @Size(min = 6, message = "La contraseña debe tener mínimo 6 caracteres")
    private String contrasena;
}

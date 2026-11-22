package com.GAV.gav.DTO.Request;

import com.GAV.gav.Model.Usuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Data;

// Campos que el cliente puede modificar de su propio perfil.
// Datos sensibles (nombre, apellidos, documento, fecha de nacimiento) están
// bloqueados y solo el admin puede cambiarlos. Todos los campos son opcionales.
@Data
public class ActualizarPerfilClienteRequest {

    private Usuario.Genero genero;

    private String telefono;

    @Email(message = "El correo no tiene un formato válido")
    private String email;

    @Size(min = 6, message = "La contraseña debe tener mínimo 6 caracteres")
    private String contrasena;
}

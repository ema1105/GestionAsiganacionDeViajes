package com.GAV.gav.DTO.Request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.Size;
import lombok.Data;

// Campos que el admin puede modificar de su propio perfil.
// Todos los campos son opcionales (null = no modificar).
@Data
public class ActualizarPerfilAdminRequest {

    @Email(message = "El correo no tiene un formato válido")
    private String email;

    private String telefono;

    @Size(min = 6, message = "La contraseña debe tener mínimo 6 caracteres")
    private String contrasena;
}

package com.GAV.gav.DTO.Request;

import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.Usuario;
import jakarta.validation.constraints.*;
import lombok.Data;

import java.util.Date;

// DTO que el admin usa para registrar un nuevo conductor.
// Incluye tanto los datos del usuario como los específicos del conductor y su vehículo.
// El automóvil se crea en la misma transacción (no se reutiliza uno existente).
@Data
public class RegisterConductorRequest {

    // --- Datos de usuario ---
    @NotBlank(message = "El nombre completo es obligatorio")
    private String nombreCompleto;

    @NotBlank(message = "Los apellidos son obligatorios")
    private String apellidosCompletos;

    @NotNull(message = "La fecha de nacimiento es obligatoria")
    private Date fechaNacimiento;

    @NotBlank(message = "El nombre de usuario es obligatorio")
    @Size(min = 4, max = 50)
    private String nombreUsuario;

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 6)
    private String contrasena;

    @NotBlank(message = "El teléfono es obligatorio")
    private String telefono;

    @NotNull(message = "El tipo de documento es obligatorio")
    private Usuario.TipoDocumento tipoDocumento;

    @NotBlank(message = "El número de documento es obligatorio")
    private String numeroDocumento;

    @NotBlank(message = "El correo electrónico es obligatorio")
    @Email
    private String email;

    // --- Datos específicos del conductor ---
    @NotBlank(message = "El número de licencia es obligatorio")
    private String licencia;

    @NotNull(message = "El tipo de licencia es obligatorio")
    private Conductor.TipoLicencia tipoLicencia;

    // --- Datos del vehículo (se crea en la misma transacción) ---
    @NotBlank(message = "La marca del vehículo es obligatoria")
    private String marcaVehiculo;

    @NotBlank(message = "El modelo del vehículo es obligatorio")
    private String modeloVehiculo;

    @NotBlank(message = "La placa del vehículo es obligatoria")
    private String placaVehiculo;

    @Min(value = 1, message = "La capacidad máxima debe ser al menos 1")
    private int capacidadMaxima;

    // Referencia a la categoría existente en BD (ECONOMICO, PREMIUM, etc.)
    @NotNull(message = "La categoría del vehículo es obligatoria")
    private Long categoriaVehiculoId;
}

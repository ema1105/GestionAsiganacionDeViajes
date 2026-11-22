package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Usuario;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

// Vista de perfil que ve el propio cliente. Datos sensibles como read-only.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class PerfilClienteResponse {

    private Long id;

    // --- Datos sensibles (solo lectura) ---
    private String nombreCompleto;
    private String apellidosCompletos;
    private Date fechaNacimiento;
    private String nombreUsuario;
    private Usuario.TipoDocumento tipoDocumento;
    private String numeroDocumento;

    // --- Datos modificables ---
    private Usuario.Genero genero;
    private String telefono;
    private String email;
}

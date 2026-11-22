package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Usuario;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class UsuarioResponse {

    private Long id;
    private String nombreCompleto;
    private String apellidosCompletos;
    private String nombreUsuario;
    private String email;
    private String telefono;
    private Usuario.TipoDocumento tipoDocumento;
    private String numeroDocumento;
    private String rol;
}

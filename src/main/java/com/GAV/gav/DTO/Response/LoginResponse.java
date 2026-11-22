package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class LoginResponse {

    private String token;
    private String tipo = "Bearer";
    private String nombreUsuario;
    private String rol;

    public LoginResponse(String token, String nombreUsuario, String rol) {
        this.token = token;
        this.nombreUsuario = nombreUsuario;
        this.rol = rol;
    }
}

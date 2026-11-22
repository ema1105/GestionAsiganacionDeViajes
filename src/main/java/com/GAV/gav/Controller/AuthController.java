package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Request.LoginRequest;
import com.GAV.gav.DTO.Request.RegisterClienteRequest;
import com.GAV.gav.DTO.Response.LoginResponse;
import com.GAV.gav.DTO.Response.UsuarioResponse;
import com.GAV.gav.Service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

// Endpoints públicos de autenticación.
// El registro de clientes es libre; los conductores los registra el admin.
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/register/cliente")
    public ResponseEntity<UsuarioResponse> registerCliente(
            @Valid @RequestBody RegisterClienteRequest request) {
        UsuarioResponse response = authService.registerCliente(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PostMapping("/login")
    public ResponseEntity<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ResponseEntity.ok(authService.login(request));
    }
}

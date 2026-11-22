package com.GAV.gav.Security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;

// Se invoca cuando la petición llega SIN autenticación válida (token ausente,
// expirado, malformado o firma inválida). Devuelve 401 con cuerpo JSON claro,
// en lugar del 403 genérico de Spring que confunde "no autenticado" con
// "autenticado pero sin permiso".
@Slf4j
@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void commence(HttpServletRequest request,
                         HttpServletResponse response,
                         AuthenticationException authException) throws IOException {

        log.warn("[401] Acceso no autenticado a {} {} — {}",
                request.getMethod(), request.getRequestURI(), authException.getMessage());

        response.setStatus(HttpStatus.UNAUTHORIZED.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), Map.of(
                "status", 401,
                "error", "Unauthorized",
                "mensaje", "Sesión no válida o expirada. Inicia sesión nuevamente.",
                "path", request.getRequestURI(),
                "timestamp", Instant.now().toString()
        ));
    }
}

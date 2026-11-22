package com.GAV.gav.Security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.access.AccessDeniedHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.time.Instant;
import java.util.Map;

// Se invoca SOLO cuando el usuario SÍ está autenticado pero NO tiene el rol
// requerido para el endpoint (403 real). Loguea el usuario y sus roles para
// diagnóstico inmediato de conflictos de permisos.
@Slf4j
@Component
public class RestAccessDeniedHandler implements AccessDeniedHandler {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public void handle(HttpServletRequest request,
                       HttpServletResponse response,
                       AccessDeniedException accessDeniedException) throws IOException {

        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String usuario = auth != null ? auth.getName() : "desconocido";
        Object roles = auth != null ? auth.getAuthorities() : "[]";

        log.warn("[403] Usuario '{}' con roles {} sin permiso para {} {}",
                usuario, roles, request.getMethod(), request.getRequestURI());

        response.setStatus(HttpStatus.FORBIDDEN.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), Map.of(
                "status", 403,
                "error", "Forbidden",
                "mensaje", "No tienes permisos para realizar esta acción con tu rol actual.",
                "path", request.getRequestURI(),
                "timestamp", Instant.now().toString()
        ));
    }
}

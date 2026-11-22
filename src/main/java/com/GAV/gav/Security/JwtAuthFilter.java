package com.GAV.gav.Security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

// Filtro que intercepta cada request HTTP y valida el token JWT del header Authorization.
// Si el token es válido, establece la autenticación en el SecurityContext para que
// Spring Security considere al usuario como autenticado durante el ciclo de vida del request.
@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthFilter extends OncePerRequestFilter {

    private final JwtService jwtService;
    private final UserDetailsServiceImpl userDetailsService;

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {

        final String authHeader = request.getHeader("Authorization");

        // Si no hay header Authorization o no comienza con "Bearer ", continúa sin autenticar
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        final String jwt = authHeader.substring(7);
        final String nombreUsuario;

        try {
            nombreUsuario = jwtService.extractUsername(jwt);
        } catch (io.jsonwebtoken.ExpiredJwtException e) {
            // Token expirado: causa frecuente de 403 confuso. Se deja pasar sin
            // autenticar → el EntryPoint responderá 401 (no 403) y el front
            // limpiará la sesión y redirigirá al login.
            log.warn("[JWT] Token EXPIRADO para {} {} — {}",
                    request.getMethod(), request.getRequestURI(), e.getMessage());
            filterChain.doFilter(request, response);
            return;
        } catch (Exception e) {
            log.warn("[JWT] Token inválido/malformado en {} {} — {}: {}",
                    request.getMethod(), request.getRequestURI(),
                    e.getClass().getSimpleName(), e.getMessage());
            filterChain.doFilter(request, response);
            return;
        }

        // Solo autentica si hay username y no hay autenticación previa en el contexto
        if (nombreUsuario != null && SecurityContextHolder.getContext().getAuthentication() == null) {
            try {
                UserDetails userDetails = userDetailsService.loadUserByUsername(nombreUsuario);

                if (jwtService.isTokenValid(jwt, userDetails)) {
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userDetails, null, userDetails.getAuthorities()
                    );
                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                    log.debug("[JWT] Autenticado '{}' con roles {} para {} {}",
                            nombreUsuario, userDetails.getAuthorities(),
                            request.getMethod(), request.getRequestURI());
                } else {
                    log.warn("[JWT] Token no válido para '{}' (expirado o username no coincide)",
                            nombreUsuario);
                }
            } catch (org.springframework.security.core.userdetails.UsernameNotFoundException e) {
                // El usuario del token ya no existe en BD.
                log.warn("[JWT] Usuario del token no existe en BD: '{}'", nombreUsuario);
            }
        }

        filterChain.doFilter(request, response);
    }
}

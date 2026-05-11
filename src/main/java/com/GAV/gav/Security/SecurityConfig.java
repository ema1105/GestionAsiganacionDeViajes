package com.GAV.gav.Security;

import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.AuthenticationProvider;
import org.springframework.security.authentication.dao.DaoAuthenticationProvider;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.Arrays;
import java.util.List;

// Configuración central de Spring Security.
// La API es stateless (JWT), por eso la sesión HTTP está deshabilitada (STATELESS).
// Los endpoints se protegen por rol; los controllers los usarán una vez integrados.
//
// CORS: configurado para permitir el frontend React (puertos típicos de Vite/CRA).
// Los orígenes permitidos se leen de la propiedad `cors.allowed-origins`.
@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthFilter jwtAuthFilter;
    private final UserDetailsServiceImpl userDetailsService;

    // Lista de orígenes permitidos para CORS, configurable por property.
    // Default: ambos puertos típicos de desarrollo de React (Vite y CRA).
    @Value("${cors.allowed-origins:http://localhost:5173,http://localhost:3000}")
    private String[] allowedOrigins;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(AbstractHttpConfigurer::disable)
            .sessionManagement(session ->
                session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                // Endpoints públicos: registro y login no requieren token
                .requestMatchers("/api/auth/**").permitAll()
                // Documentación Swagger (SpringDoc)
                .requestMatchers(
                    "/swagger-ui/**",
                    "/swagger-ui.html",
                    "/v3/api-docs/**"
                ).permitAll()
                // Solo el admin puede registrar conductores y gestionar la plataforma
                .requestMatchers("/api/admin/**").hasRole("ADMIN")
                // Recepcionista: check-in de huéspedes y solicitud de viajes en su nombre
                .requestMatchers("/api/recepcionista/**").hasRole("RECEPCIONISTA")
                // Operaciones del cliente (solicitar viaje, cancelar, ver sus viajes)
                .requestMatchers("/api/cliente/**").hasRole("CLIENTE")
                // Operaciones del conductor (responder solicitudes, gestionar viaje en curso)
                .requestMatchers("/api/conductor/**").hasRole("CONDUCTOR")
                // Notificaciones: cualquier usuario autenticado consulta las suyas
                .requestMatchers("/api/notificaciones/**").authenticated()
                // Cualquier otro endpoint requiere autenticación
                .anyRequest().authenticated()
            )
            .authenticationProvider(authenticationProvider())
            .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    // CORS: configuración aplicada globalmente.
    // Permite los métodos típicos REST y todos los headers (incluido Authorization para JWT).
    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOrigins(Arrays.asList(allowedOrigins));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Authorization"));
        // allowCredentials=true requiere orígenes específicos (no "*"), por eso usamos la lista.
        config.setAllowCredentials(true);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    // Proveedor de autenticación que usa UserDetailsService + BCrypt para validar credenciales.
    // CAMBIO: en Spring Security 6.4+ DaoAuthenticationProvider exige el UserDetailsService
    // por constructor; el setter setUserDetailsService(...) fue removido.
    @Bean
    public AuthenticationProvider authenticationProvider() {
        DaoAuthenticationProvider provider = new DaoAuthenticationProvider(userDetailsService);
        provider.setPasswordEncoder(passwordEncoder());
        return provider;
    }

    // Expuesto como bean para que AuthService pueda inyectarlo y autenticar en el login
    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration config)
            throws Exception {
        return config.getAuthenticationManager();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }
}

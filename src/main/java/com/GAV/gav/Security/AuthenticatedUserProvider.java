package com.GAV.gav.Security;

import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.Usuario;
import com.GAV.gav.Repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

// Helper centralizado para obtener el Usuario autenticado a partir del SecurityContext.
// Evita repetir la lógica de extraer el username y buscar el Usuario en cada controller.
@Component
@RequiredArgsConstructor
public class AuthenticatedUserProvider {

    private final UsuarioRepository usuarioRepository;

    public Usuario getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            throw new BusinessException("No hay un usuario autenticado.", HttpStatus.UNAUTHORIZED);
        }

        String username = authentication.getName();
        return usuarioRepository.findByNombreUsuario(username)
                .orElseThrow(() -> new BusinessException(
                        "Usuario autenticado no encontrado en BD: " + username,
                        HttpStatus.UNAUTHORIZED));
    }

    public Long getCurrentUserId() {
        return getCurrentUser().getId();
    }
}

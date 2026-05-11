package com.GAV.gav.Security;

import com.GAV.gav.Model.Usuario;
import com.GAV.gav.Repository.ConductorRepository;
import com.GAV.gav.Repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

// Implementación de UserDetailsService requerida por Spring Security.
// Conecta la entidad Usuario con el sistema de autenticación de Spring.
// El rol del usuario se convierte en un GrantedAuthority con prefijo ROLE_.
//
// CAMBIO: si el usuario es un Conductor con activo=false, se devuelve UserDetails
// con enabled=false. Spring Security lo rechaza con DisabledException → 401.
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UsuarioRepository usuarioRepository;
    private final ConductorRepository conductorRepository;

    @Override
    public UserDetails loadUserByUsername(String nombreUsuario) throws UsernameNotFoundException {
        Usuario usuario = usuarioRepository.findByNombreUsuario(nombreUsuario)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "Usuario no encontrado: " + nombreUsuario));

        String rolNombre = (usuario.getRol() != null)
                ? usuario.getRol().getNombre()
                : "ROLE_CLIENTE";

        // Spring Security espera que los roles tengan el prefijo ROLE_
        String authority = rolNombre.startsWith("ROLE_") ? rolNombre : "ROLE_" + rolNombre;

        // Si es conductor, verificar que esté activo (NULL en BD se considera activo)
        boolean enabled = true;
        if ("ROLE_CONDUCTOR".equals(authority)) {
            enabled = conductorRepository.findByUsuarioId(usuario.getId())
                    .map(c -> c.getActivo() == null || Boolean.TRUE.equals(c.getActivo()))
                    .orElse(true);
        }

        return User.builder()
                .username(usuario.getNombreUsuario())
                .password(usuario.getContrasena())
                .authorities(List.of(new SimpleGrantedAuthority(authority)))
                .disabled(!enabled)
                .accountExpired(false)
                .accountLocked(false)
                .credentialsExpired(false)
                .build();
    }
}

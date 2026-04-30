package com.GAV.gav.Security;

import com.GAV.gav.Model.Usuario;
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
@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UsuarioRepository usuarioRepository;

    @Override
    public UserDetails loadUserByUsername(String nombreUsuario) throws UsernameNotFoundException {
        Usuario usuario = usuarioRepository.findByNombreUsuario(nombreUsuario)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "Usuario no encontrado: " + nombreUsuario));

        String rolNombre = (usuario.getRol() != null)
                ? usuario.getRol().getNombre()
                : "ROLE_CLIENTE";

        // Spring Security espera que los roles tengan el prefijo ROLE_
        // Si en BD ya están con prefijo (ej: "ROLE_ADMIN") se usa tal cual;
        // si no tienen prefijo (ej: "ADMIN"), se agrega aquí
        String authority = rolNombre.startsWith("ROLE_") ? rolNombre : "ROLE_" + rolNombre;

        return new User(
                usuario.getNombreUsuario(),
                usuario.getContrasena(),
                List.of(new SimpleGrantedAuthority(authority))
        );
    }
}

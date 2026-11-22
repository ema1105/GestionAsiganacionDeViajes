package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.LoginRequest;
import com.GAV.gav.DTO.Request.RegisterClienteRequest;
import com.GAV.gav.DTO.Response.LoginResponse;
import com.GAV.gav.DTO.Response.UsuarioResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.Rol;
import com.GAV.gav.Model.Usuario;
import com.GAV.gav.Repository.RolRepository;
import com.GAV.gav.Repository.UsuarioRepository;
import com.GAV.gav.Security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

// Gestiona el registro de clientes y el inicio de sesión para todos los roles.
// El login es unificado: el sistema determina el rol desde la BD y lo incluye en el JWT.
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final JwtService jwtService;
    private final UserDetailsService userDetailsService;

    // Registro exclusivo para clientes.
    // Los conductores los registra el admin (AdminService.registrarConductor).
    @Transactional
    public UsuarioResponse registerCliente(RegisterClienteRequest request) {
        validarCamposUnicos(request.getEmail(), request.getTelefono(),
                request.getNumeroDocumento(), request.getNombreUsuario());

        // El rol ROLE_CLIENTE debe existir en BD antes del primer registro
        Rol rolCliente = rolRepository.findByNombre("ROLE_CLIENTE")
                .orElseThrow(() -> new BusinessException(
                        "Rol ROLE_CLIENTE no encontrado. Contacte al administrador.",
                        HttpStatus.INTERNAL_SERVER_ERROR));

        Usuario usuario = new Usuario();
        usuario.setNombreCompleto(request.getNombreCompleto());
        usuario.setApellidosCompletos(request.getApellidosCompletos());
        usuario.setFechaNacimiento(request.getFechaNacimiento());
        usuario.setNombreUsuario(request.getNombreUsuario());
        // La contraseña se almacena hasheada con BCrypt, nunca en texto plano
        usuario.setContrasena(passwordEncoder.encode(request.getContrasena()));
        usuario.setTelefono(request.getTelefono());
        usuario.setTipoDocumento(request.getTipoDocumento());
        usuario.setNumeroDocumento(request.getNumeroDocumento());
        usuario.setEmail(request.getEmail());
        usuario.setRol(rolCliente);

        Usuario guardado = usuarioRepository.save(usuario);
        return mapToUsuarioResponse(guardado);
    }

    // Login unificado para ADMIN, CLIENTE y CONDUCTOR.
    // Spring Security valida credenciales; si pasan, se genera el JWT con el rol del usuario.
    public LoginResponse login(LoginRequest request) {
        // Lanza BadCredentialsException si usuario o contraseña no coinciden
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                        request.getNombreUsuario(),
                        request.getContrasena()
                )
        );

        UserDetails userDetails = userDetailsService.loadUserByUsername(request.getNombreUsuario());
        String token = jwtService.generateToken(userDetails);

        String rol = userDetails.getAuthorities().stream()
                .findFirst()
                .map(Object::toString)
                .orElse("");

        return new LoginResponse(token, request.getNombreUsuario(), rol);
    }

    // Verifica que los campos únicos no estén ya registrados en BD
    private void validarCamposUnicos(String email, String telefono,
                                      String numeroDocumento, String nombreUsuario) {
        if (usuarioRepository.existsByEmail(email))
            throw new BusinessException("El correo ya está registrado.", HttpStatus.CONFLICT);
        if (usuarioRepository.existsByTelefono(telefono))
            throw new BusinessException("El teléfono ya está registrado.", HttpStatus.CONFLICT);
        if (usuarioRepository.existsByNumeroDocumento(numeroDocumento))
            throw new BusinessException("El número de documento ya está registrado.", HttpStatus.CONFLICT);
        if (usuarioRepository.existsByNombreUsuario(nombreUsuario))
            throw new BusinessException("El nombre de usuario ya está en uso.", HttpStatus.CONFLICT);
    }

    private UsuarioResponse mapToUsuarioResponse(Usuario u) {
        return UsuarioResponse.builder()
                .id(u.getId())
                .nombreCompleto(u.getNombreCompleto())
                .apellidosCompletos(u.getApellidosCompletos())
                .nombreUsuario(u.getNombreUsuario())
                .email(u.getEmail())
                .telefono(u.getTelefono())
                .tipoDocumento(u.getTipoDocumento())
                .numeroDocumento(u.getNumeroDocumento())
                .rol(u.getRol() != null ? u.getRol().getNombre() : null)
                .build();
    }
}

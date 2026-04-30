package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.RegisterConductorRequest;
import com.GAV.gav.DTO.Response.ConductorResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

// Lógica exclusiva del rol ADMIN.
// El admin registra conductores (junto con su vehículo) en una única transacción.
// El conductor queda disponible de inmediato y entra al pool FIFO desde el momento de registro.
@Service
@RequiredArgsConstructor
public class AdminService {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final ConductorRepository conductorRepository;
    private final AutomovilRepository automovilRepository;
    private final CategoriaVehiculoRepository categoriaVehiculoRepository;
    private final PasswordEncoder passwordEncoder;

    // Crea el Usuario, el Automovil y el Conductor en una sola transacción.
    // Si cualquier paso falla, todo se revierte (atomicidad garantizada por @Transactional).
    @Transactional
    public ConductorResponse registrarConductor(RegisterConductorRequest request) {
        validarCamposUnicos(request.getEmail(), request.getTelefono(),
                request.getNumeroDocumento(), request.getNombreUsuario());

        Rol rolConductor = rolRepository.findByNombre("ROLE_CONDUCTOR")
                .orElseThrow(() -> new BusinessException(
                        "Rol ROLE_CONDUCTOR no encontrado. Contacte al administrador.",
                        HttpStatus.INTERNAL_SERVER_ERROR));

        CategoriaVehiculo categoria = categoriaVehiculoRepository
                .findById(request.getCategoriaVehiculoId())
                .orElseThrow(() -> new BusinessException(
                        "Categoría de vehículo no encontrada: " + request.getCategoriaVehiculoId(),
                        HttpStatus.BAD_REQUEST));

        // Paso 1: crear y guardar el Usuario base
        Usuario usuario = new Usuario();
        usuario.setNombreCompleto(request.getNombreCompleto());
        usuario.setApellidosCompletos(request.getApellidosCompletos());
        usuario.setFechaNacimiento(request.getFechaNacimiento());
        usuario.setNombreUsuario(request.getNombreUsuario());
        usuario.setContrasena(passwordEncoder.encode(request.getContrasena()));
        usuario.setTelefono(request.getTelefono());
        usuario.setTipoDocumento(request.getTipoDocumento());
        usuario.setNumeroDocumento(request.getNumeroDocumento());
        usuario.setEmail(request.getEmail());
        usuario.setRol(rolConductor);
        Usuario usuarioGuardado = usuarioRepository.save(usuario);

        // Paso 2: crear el vehículo asociado al conductor
        Automovil automovil = new Automovil();
        automovil.setMarca(request.getMarcaVehiculo());
        automovil.setModelo(request.getModeloVehiculo());
        automovil.setPlaca(request.getPlacaVehiculo());
        automovil.setCapacidadMaxima(request.getCapacidadMaxima());
        automovil.setCategoria(categoria);
        Automovil automovilGuardado = automovilRepository.save(automovil);

        // Paso 3: crear el Conductor.
        // disponibilidad=true y fechaDisponibleDesde=now() → entra al pool FIFO inmediatamente.
        Conductor conductor = new Conductor(
                null,
                usuarioGuardado,
                true,
                request.getLicencia(),
                request.getTipoLicencia(),
                automovilGuardado,
                LocalDateTime.now()
        );
        Conductor conductorGuardado = conductorRepository.save(conductor);

        return mapToConductorResponse(conductorGuardado);
    }

    public List<ConductorResponse> listarConductores() {
        return conductorRepository.findAll()
                .stream()
                .map(this::mapToConductorResponse)
                .toList();
    }

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

    private ConductorResponse mapToConductorResponse(Conductor c) {
        Automovil auto = c.getAutomovil();
        return ConductorResponse.builder()
                .usuarioId(c.getUsuarioId())
                .nombreCompleto(c.getUsuario().getNombreCompleto())
                .apellidosCompletos(c.getUsuario().getApellidosCompletos())
                .email(c.getUsuario().getEmail())
                .telefono(c.getUsuario().getTelefono())
                .licencia(c.getLicencia())
                .tipoLicencia(c.getTipoLicencia())
                .disponibilidad(c.getDisponibilidad())
                .marcaVehiculo(auto != null ? auto.getMarca() : null)
                .modeloVehiculo(auto != null ? auto.getModelo() : null)
                .placaVehiculo(auto != null ? auto.getPlaca() : null)
                .capacidadMaxima(auto != null ? auto.getCapacidadMaxima() : 0)
                .categoriaVehiculo(auto != null && auto.getCategoria() != null
                        ? auto.getCategoria().getNombre() : null)
                .build();
    }
}

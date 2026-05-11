package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.RegisterClienteRequest;
import com.GAV.gav.DTO.Request.SolicitarViajeRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.Usuario;
import com.GAV.gav.Model.Viaje;
import com.GAV.gav.Repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

// Lógica del rol RECEPCIONISTA: gestiona check-in de clientes (huéspedes) y
// solicita viajes en su nombre. Vista read-only de viajes y conductores.
// No gestiona conductores/vehículos (eso es del admin) ni ve estadísticas financieras.
@Service
@RequiredArgsConstructor
public class RecepcionistaService {

    private final AuthService authService;
    private final ViajeService viajeService;
    private final AdminService adminService;
    private final UsuarioRepository usuarioRepository;

    // Check-in: registra un cliente nuevo (huésped). Delega a AuthService
    // para reusar la misma validación y hashing de contraseña.
    public UsuarioResponse registrarCliente(RegisterClienteRequest request) {
        return authService.registerCliente(request);
    }

    // Solicita un viaje en nombre de un cliente existente. La recepcionista
    // pasa el clienteId; el resto del request es idéntico al de /api/cliente/viajes.
    public ViajeResponse solicitarViajeParaCliente(Long clienteId, SolicitarViajeRequest request) {
        Usuario cliente = usuarioRepository.findById(clienteId)
                .orElseThrow(() -> new BusinessException(
                        "Cliente no encontrado: " + clienteId, HttpStatus.NOT_FOUND));

        // Validar que el usuario referenciado sea realmente un cliente
        String rol = cliente.getRol() != null ? cliente.getRol().getNombre() : "";
        if (!"ROLE_CLIENTE".equals(rol)) {
            throw new BusinessException(
                    "El usuario " + clienteId + " no tiene rol ROLE_CLIENTE.",
                    HttpStatus.BAD_REQUEST);
        }

        return viajeService.solicitarViaje(request, clienteId);
    }

    // Vista read-only del historial de viajes (mismos filtros y paginación que admin).
    public PageResponse<ViajeResponse> listarViajes(
            Viaje.EstadoViaje estado, Long clienteId, Long conductorId,
            LocalDateTime desde, LocalDateTime hasta, int page, int size) {
        return adminService.listarViajes(estado, clienteId, conductorId, desde, hasta, page, size);
    }

    public ViajeResponse obtenerViaje(Long viajeId) {
        return viajeService.obtenerViajePorId(viajeId);
    }

    // Vista read-only del listado de conductores (sin inactivos por default).
    public List<ConductorResponse> listarConductores(Boolean disponibilidad,
                                                      Conductor.TipoLicencia tipoLicencia) {
        return adminService.listarConductores(disponibilidad, tipoLicencia, false);
    }
}

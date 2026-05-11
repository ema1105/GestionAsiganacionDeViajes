package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.ActualizarPerfilClienteRequest;
import com.GAV.gav.DTO.Request.CalificarViajeRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

// Lógica de negocio exclusiva del rol CLIENTE.
// Acciones: gestión de perfil propio, consulta de viaje activo / detalle, historial paginado
// y calificación del conductor al finalizar el viaje.
// La solicitud y cancelación de viajes vive en ViajeService (compartido con el FIFO).
@Service
@RequiredArgsConstructor
public class ClienteService {

    private final UsuarioRepository usuarioRepository;
    private final ViajeRepository viajeRepository;
    private final ConductorRepository conductorRepository;
    private final CalificacionRepository calificacionRepository;
    private final ViajeService viajeService;
    private final NotificacionService notificacionService;
    private final PasswordEncoder passwordEncoder;

    // ========================================================================
    // PERFIL DEL CLIENTE
    // ========================================================================

    public PerfilClienteResponse obtenerPerfil(Long clienteId) {
        Usuario u = usuarioRepository.findById(clienteId)
                .orElseThrow(() -> new BusinessException(
                        "Cliente no encontrado: " + clienteId, HttpStatus.NOT_FOUND));
        return mapToPerfilResponse(u);
    }

    // Actualización parcial. Datos sensibles ignorados (no están en el request).
    @Transactional
    public PerfilClienteResponse actualizarPerfil(Long clienteId,
                                                   ActualizarPerfilClienteRequest req) {
        Usuario u = usuarioRepository.findById(clienteId)
                .orElseThrow(() -> new BusinessException(
                        "Cliente no encontrado: " + clienteId, HttpStatus.NOT_FOUND));

        if (req.getGenero() != null)    u.setGenero(req.getGenero());
        if (req.getTelefono() != null)  u.setTelefono(req.getTelefono());
        if (req.getEmail() != null)     u.setEmail(req.getEmail());
        if (req.getContrasena() != null && !req.getContrasena().isBlank()) {
            u.setContrasena(passwordEncoder.encode(req.getContrasena()));
        }
        usuarioRepository.save(u);

        return mapToPerfilResponse(u);
    }

    // ========================================================================
    // MAPA / VIAJE ACTIVO Y DETALLE
    // ========================================================================

    // Único viaje del cliente "abierto" (cualquier estado distinto de FINALIZADO/CANCELADO).
    public ViajeResponse obtenerViajeActivo(Long clienteId) {
        return viajeRepository.findByClienteId(clienteId)
                .stream()
                .filter(v -> v.getEstadoViaje() != Viaje.EstadoViaje.FINALIZADO
                        && v.getEstadoViaje() != Viaje.EstadoViaje.CANCELADO)
                .findFirst()
                .map(viajeService::mapToViajeResponse)
                .orElse(null);
    }

    // Detalle expandido con datos del conductor y del vehículo.
    public ViajeDetalleClienteResponse obtenerDetalleViaje(Long viajeId, Long clienteId) {
        Viaje v = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));

        if (v.getCliente() == null || !v.getCliente().getId().equals(clienteId)) {
            throw new BusinessException(
                    "El cliente " + clienteId + " no es el solicitante de este viaje.",
                    HttpStatus.FORBIDDEN);
        }

        Usuario conductor = v.getConductor();
        Automovil auto = v.getAutomovil();

        return ViajeDetalleClienteResponse.builder()
                .id(v.getId())
                .estadoViaje(v.getEstadoViaje())
                .cantidadPasajeros(v.getCantidadPasajeros())
                .origenLat(v.getOrigenLat())
                .origenLng(v.getOrigenLng())
                .destinoLat(v.getDestinoLat())
                .destinoLng(v.getDestinoLng())
                .precioCalculado(v.getPrecioCalculado())
                .fechaSolicitud(v.getFechaSolicitud())
                .fechaInicio(v.getFechaInicio())
                .fechaFinalizacion(v.getFechaFinalizacion())
                .conductorId(conductor != null ? conductor.getId() : null)
                .conductorNombre(conductor != null ? conductor.getNombreCompleto() : null)
                .conductorApellidos(conductor != null ? conductor.getApellidosCompletos() : null)
                .conductorTelefono(conductor != null ? conductor.getTelefono() : null)
                .vehiculoMarca(auto != null ? auto.getMarca() : null)
                .vehiculoModelo(auto != null ? auto.getModelo() : null)
                .vehiculoPlaca(auto != null ? auto.getPlaca() : null)
                .vehiculoCategoria(auto != null && auto.getCategoria() != null
                        ? auto.getCategoria().getNombre() : null)
                .build();
    }

    // ========================================================================
    // HISTORIAL PAGINADO DEL CLIENTE
    // ========================================================================

    public PageResponse<ViajeResponse> historialViajes(Long clienteId,
                                                        Viaje.EstadoViaje estado,
                                                        LocalDateTime desde,
                                                        LocalDateTime hasta,
                                                        int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        // Reusa la query genérica de admin pero fijando clienteId.
        Page<Viaje> resultado = viajeRepository.findConFiltros(
                estado, clienteId, null, desde, hasta, pageable);
        return PageResponse.from(resultado, viajeService::mapToViajeResponse);
    }

    // ========================================================================
    // CALIFICACIÓN AL CONDUCTOR
    // ========================================================================

    @Transactional
    public CalificacionResponse calificarConductor(Long viajeId, Long clienteId,
                                                    CalificarViajeRequest req) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));

        // Validar ownership del cliente
        if (viaje.getCliente() == null || !viaje.getCliente().getId().equals(clienteId)) {
            throw new BusinessException(
                    "El cliente " + clienteId + " no es el solicitante de este viaje.",
                    HttpStatus.FORBIDDEN);
        }

        // Solo se puede calificar un viaje FINALIZADO
        if (viaje.getEstadoViaje() != Viaje.EstadoViaje.FINALIZADO) {
            throw new BusinessException(
                    "Solo se puede calificar un viaje FINALIZADO. Estado actual: "
                            + viaje.getEstadoViaje(),
                    HttpStatus.CONFLICT);
        }

        // Debe haber conductor asignado
        Usuario conductor = viaje.getConductor();
        if (conductor == null) {
            throw new BusinessException(
                    "El viaje no tiene un conductor asignado, no se puede calificar.",
                    HttpStatus.CONFLICT);
        }

        // Evitar doble calificación del mismo viaje por el mismo cliente
        boolean yaExiste = calificacionRepository.existsByViajeIdAndCalificadorIdAndTipoCalificacion(
                viajeId, clienteId, Calificacion.TipoCalificacion.CLIENTE_A_CONDUCTOR);
        if (yaExiste) {
            throw new BusinessException(
                    "Ya calificaste este viaje. No se permite calificar más de una vez.",
                    HttpStatus.CONFLICT);
        }

        Usuario cliente = viaje.getCliente();

        Calificacion calificacion = new Calificacion();
        calificacion.setViaje(viaje);
        calificacion.setCalificador(cliente);
        calificacion.setCalificado(conductor);
        calificacion.setTipoCalificacion(Calificacion.TipoCalificacion.CLIENTE_A_CONDUCTOR);
        calificacion.setPuntuacion(req.getPuntuacion());
        calificacion.setComentario(req.getComentario());
        calificacion.setFechaCalificacion(LocalDateTime.now());

        Calificacion guardada = calificacionRepository.save(calificacion);

        // Notificar al conductor que recibió una nueva calificación
        notificacionService.crear(
                conductor,
                viaje,
                Notificacion.TipoNotificacion.NUEVA_CALIFICACION,
                cliente.getNombreCompleto() + " calificó tu servicio con "
                        + req.getPuntuacion() + "/5 en el viaje #" + viaje.getId() + "."
        );

        return mapToCalificacionResponse(guardada);
    }

    // ========================================================================
    // VISUALIZACIÓN DE CALIFICACIONES RECIBIDAS (CONDUCTOR_A_CLIENTE)
    // ========================================================================

    public PageResponse<CalificacionResponse> obtenerCalificacionesRecibidas(
            Long clienteId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Calificacion> resultado = calificacionRepository.findByCalificadoIdAndTipo(
                clienteId, Calificacion.TipoCalificacion.CONDUCTOR_A_CLIENTE, pageable);
        return PageResponse.from(resultado, this::mapToCalificacionResponse);
    }

    public PromedioCalificacionResponse obtenerPromedioCalificaciones(Long clienteId) {
        Double promedio = calificacionRepository.obtenerPromedioPorTipo(
                clienteId, Calificacion.TipoCalificacion.CONDUCTOR_A_CLIENTE);
        long total = calificacionRepository.countByCalificadoIdAndTipoCalificacion(
                clienteId, Calificacion.TipoCalificacion.CONDUCTOR_A_CLIENTE);
        return PromedioCalificacionResponse.builder()
                .promedio(promedio)
                .totalCalificaciones(total)
                .build();
    }

    // ========================================================================
    // Helpers de mapeo
    // ========================================================================

    private PerfilClienteResponse mapToPerfilResponse(Usuario u) {
        return PerfilClienteResponse.builder()
                .id(u.getId())
                .nombreCompleto(u.getNombreCompleto())
                .apellidosCompletos(u.getApellidosCompletos())
                .fechaNacimiento(u.getFechaNacimiento())
                .nombreUsuario(u.getNombreUsuario())
                .tipoDocumento(u.getTipoDocumento())
                .numeroDocumento(u.getNumeroDocumento())
                .genero(u.getGenero())
                .telefono(u.getTelefono())
                .email(u.getEmail())
                .build();
    }

    private CalificacionResponse mapToCalificacionResponse(Calificacion c) {
        return CalificacionResponse.builder()
                .id(c.getId())
                .viajeId(c.getViaje() != null ? c.getViaje().getId() : null)
                .calificadorId(c.getCalificador() != null ? c.getCalificador().getId() : null)
                .calificadorNombre(c.getCalificador() != null
                        ? c.getCalificador().getNombreCompleto() : null)
                .calificadoId(c.getCalificado() != null ? c.getCalificado().getId() : null)
                .calificadoNombre(c.getCalificado() != null
                        ? c.getCalificado().getNombreCompleto() : null)
                .tipoCalificacion(c.getTipoCalificacion())
                .puntuacion(c.getPuntuacion())
                .comentario(c.getComentario())
                .fechaCalificacion(c.getFechaCalificacion())
                .build();
    }
}

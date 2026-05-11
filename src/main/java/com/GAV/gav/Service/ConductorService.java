package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.ActualizarPerfilConductorRequest;
import com.GAV.gav.DTO.Request.CalificarViajeRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Model.Calificacion;
import com.GAV.gav.Repository.*;
import com.GAV.gav.Repository.CalificacionRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

// Lógica de negocio exclusiva del rol CONDUCTOR.
// Acciones: responder solicitud (aceptar/rechazar), avanzar el viaje por la máquina
// de estados (EN_CAMINO, EN_CURSO, FINALIZADO), cancelar; gestionar perfil propio,
// consultar viaje activo y detalle, historial paginado y estadísticas personales.
@Service
@RequiredArgsConstructor
public class ConductorService {

    private final ConductorRepository conductorRepository;
    private final ViajeConductorRepository viajeConductorRepository;
    private final ViajeRepository viajeRepository;
    private final ViajeService viajeService;
    private final NotificacionService notificacionService;
    private final UsuarioRepository usuarioRepository;
    private final CalificacionRepository calificacionRepository;
    private final PasswordEncoder passwordEncoder;

    // ========================================================================
    // GESTIÓN DE SOLICITUDES Y MÁQUINA DE ESTADOS DEL VIAJE
    // ========================================================================

    @Transactional
    public ViajeResponse responderSolicitud(Long viajeId, Long conductorId, boolean aceptar) {
        ViajeConductor solicitud = viajeConductorRepository
                .findByViajeIdAndConductorUsuarioId(viajeId, conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Solicitud no encontrada para el viaje " + viajeId
                                + " y conductor " + conductorId,
                        HttpStatus.NOT_FOUND));

        if (solicitud.getEstado() != ViajeConductor.EstadoSolicitud.PENDIENTE) {
            throw new BusinessException(
                    "La solicitud ya fue procesada (estado: " + solicitud.getEstado() + ")",
                    HttpStatus.CONFLICT);
        }

        Viaje viaje = solicitud.getViaje();
        solicitud.setFechaRespuesta(LocalDateTime.now());

        if (aceptar) {
            return procesarAceptacion(solicitud, viaje);
        } else {
            return procesarRechazo(solicitud, viaje);
        }
    }

    private ViajeResponse procesarAceptacion(ViajeConductor solicitud, Viaje viaje) {
        solicitud.setEstado(ViajeConductor.EstadoSolicitud.ACEPTADO);
        viajeConductorRepository.save(solicitud);

        Conductor conductor = solicitud.getConductor();

        viaje.setConductor(conductor.getUsuario());
        viaje.setAutomovil(conductor.getAutomovil());
        viaje.setEstadoViaje(Viaje.EstadoViaje.ACEPTADO);
        viajeRepository.save(viaje);

        conductor.setDisponibilidad(false);
        conductor.setFechaDisponibleDesde(null);
        conductorRepository.save(conductor);

        notificacionService.crear(
                viaje.getCliente(),
                viaje,
                Notificacion.TipoNotificacion.CONDUCTOR_ASIGNADO,
                "Tu conductor " + conductor.getUsuario().getNombreCompleto()
                        + " aceptó el viaje #" + viaje.getId() + "."
        );

        return viajeService.mapToViajeResponse(viaje);
    }

    private ViajeResponse procesarRechazo(ViajeConductor solicitud, Viaje viaje) {
        solicitud.setEstado(ViajeConductor.EstadoSolicitud.RECHAZADO);
        viajeConductorRepository.save(solicitud);

        viaje.setEstadoViaje(Viaje.EstadoViaje.BUSCANDO_CONDUCTOR);
        viajeRepository.save(viaje);
        viajeService.asignarSiguienteConductorFIFO(viaje);

        return viajeService.mapToViajeResponse(viaje);
    }

    @Transactional
    public ViajeResponse marcarEnCamino(Long viajeId, Long conductorId) {
        Viaje viaje = obtenerViajeDelConductor(viajeId, conductorId);

        if (viaje.getEstadoViaje() != Viaje.EstadoViaje.ACEPTADO) {
            throw new BusinessException(
                    "Solo un viaje ACEPTADO puede pasar a EN_CAMINO. Estado actual: "
                            + viaje.getEstadoViaje(),
                    HttpStatus.CONFLICT);
        }

        viaje.setEstadoViaje(Viaje.EstadoViaje.EN_CAMINO);
        viajeRepository.save(viaje);

        notificacionService.crear(
                viaje.getCliente(),
                viaje,
                Notificacion.TipoNotificacion.CONDUCTOR_EN_CAMINO,
                "Tu conductor está en camino al punto de origen."
        );

        return viajeService.mapToViajeResponse(viaje);
    }

    @Transactional
    public ViajeResponse iniciarViaje(Long viajeId, Long conductorId) {
        Viaje viaje = obtenerViajeDelConductor(viajeId, conductorId);

        if (viaje.getEstadoViaje() != Viaje.EstadoViaje.EN_CAMINO) {
            throw new BusinessException(
                    "Solo un viaje EN_CAMINO puede pasar a EN_CURSO. Estado actual: "
                            + viaje.getEstadoViaje(),
                    HttpStatus.CONFLICT);
        }

        viaje.setEstadoViaje(Viaje.EstadoViaje.EN_CURSO);
        viaje.setFechaInicio(LocalDateTime.now());
        viajeRepository.save(viaje);

        notificacionService.crear(
                viaje.getCliente(),
                viaje,
                Notificacion.TipoNotificacion.VIAJE_INICIADO,
                "El viaje #" + viaje.getId() + " ha iniciado."
        );

        return viajeService.mapToViajeResponse(viaje);
    }

    @Transactional
    public ViajeResponse finalizarViaje(Long viajeId, Long conductorId) {
        Viaje viaje = obtenerViajeDelConductor(viajeId, conductorId);

        if (viaje.getEstadoViaje() != Viaje.EstadoViaje.EN_CURSO) {
            throw new BusinessException(
                    "El viaje no puede finalizarse en estado: " + viaje.getEstadoViaje()
                            + ". Debe estar en EN_CURSO.",
                    HttpStatus.CONFLICT);
        }

        viaje.setEstadoViaje(Viaje.EstadoViaje.FINALIZADO);
        viaje.setFechaFinalizacion(LocalDateTime.now());
        viajeRepository.save(viaje);

        Conductor conductor = conductorRepository.findByUsuarioId(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));
        conductor.setDisponibilidad(true);
        conductor.setFechaDisponibleDesde(LocalDateTime.now());
        conductorRepository.save(conductor);

        notificacionService.crear(
                viaje.getCliente(),
                viaje,
                Notificacion.TipoNotificacion.VIAJE_FINALIZADO,
                "El viaje #" + viaje.getId() + " ha finalizado. Total: $"
                        + (viaje.getPrecioCalculado() != null
                            ? viaje.getPrecioCalculado() : "—")
        );

        return viajeService.mapToViajeResponse(viaje);
    }

    @Transactional
    public ViajeResponse cancelarViaje(Long viajeId, Long conductorId, String motivo) {
        Viaje viaje = obtenerViajeDelConductor(viajeId, conductorId);

        if (viaje.getEstadoViaje() == Viaje.EstadoViaje.EN_CURSO
                || viaje.getEstadoViaje() == Viaje.EstadoViaje.FINALIZADO
                || viaje.getEstadoViaje() == Viaje.EstadoViaje.CANCELADO) {
            throw new BusinessException(
                    "No se puede cancelar un viaje en estado: " + viaje.getEstadoViaje(),
                    HttpStatus.CONFLICT);
        }

        viaje.setEstadoViaje(Viaje.EstadoViaje.CANCELADO);
        viajeRepository.save(viaje);

        Conductor conductor = conductorRepository.findByUsuarioId(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));
        conductor.setDisponibilidad(true);
        conductor.setFechaDisponibleDesde(LocalDateTime.now());
        conductorRepository.save(conductor);

        notificacionService.crear(
                viaje.getCliente(),
                viaje,
                Notificacion.TipoNotificacion.VIAJE_CANCELADO,
                "Tu conductor canceló el viaje #" + viaje.getId()
                        + (motivo != null && !motivo.isBlank() ? " — Motivo: " + motivo : "")
        );

        return viajeService.mapToViajeResponse(viaje);
    }

    public ViajeConductor obtenerSolicitudPendiente(Long conductorId) {
        return viajeConductorRepository
                .findByConductorUsuarioId(conductorId)
                .stream()
                .filter(vc -> vc.getEstado() == ViajeConductor.EstadoSolicitud.PENDIENTE)
                .findFirst()
                .orElse(null);
    }

    public List<ViajeConductor> obtenerHistorialSolicitudes(Long conductorId) {
        return viajeConductorRepository.findByConductorUsuarioId(conductorId);
    }

    private Viaje obtenerViajeDelConductor(Long viajeId, Long conductorId) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));

        if (viaje.getConductor() == null
                || !viaje.getConductor().getId().equals(conductorId)) {
            throw new BusinessException(
                    "El conductor " + conductorId + " no está asignado a este viaje.",
                    HttpStatus.FORBIDDEN);
        }
        return viaje;
    }

    // ========================================================================
    // PERFIL DEL CONDUCTOR
    // ========================================================================

    public PerfilConductorResponse obtenerPerfil(Long conductorId) {
        Conductor c = conductorRepository.findByUsuarioId(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));
        return mapToPerfilResponse(c);
    }

    // Actualización parcial: solo campos modificables. Datos sensibles ignorados.
    @Transactional
    public PerfilConductorResponse actualizarPerfil(Long conductorId,
                                                     ActualizarPerfilConductorRequest req) {
        Conductor conductor = conductorRepository.findByUsuarioId(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));
        Usuario usuario = conductor.getUsuario();

        if (req.getGenero() != null)    usuario.setGenero(req.getGenero());
        if (req.getTelefono() != null)  usuario.setTelefono(req.getTelefono());
        if (req.getEmail() != null)     usuario.setEmail(req.getEmail());
        if (req.getContrasena() != null && !req.getContrasena().isBlank()) {
            usuario.setContrasena(passwordEncoder.encode(req.getContrasena()));
        }
        usuarioRepository.save(usuario);

        return mapToPerfilResponse(conductor);
    }

    // ========================================================================
    // MAPA / VIAJE ACTIVO Y DETALLE
    // ========================================================================

    // Devuelve el viaje en curso del conductor (ACEPTADO|EN_CAMINO|EN_CURSO).
    // null si no tiene viaje activo.
    public ViajeResponse obtenerViajeActivo(Long conductorId) {
        return viajeRepository.findViajeActivoDelConductor(conductorId)
                .stream()
                .findFirst()
                .map(viajeService::mapToViajeResponse)
                .orElse(null);
    }

    // Detalle expandido de un viaje del conductor (con datos de contacto del cliente).
    public ViajeDetalleConductorResponse obtenerDetalleViaje(Long viajeId, Long conductorId) {
        Viaje v = obtenerViajeDelConductor(viajeId, conductorId);
        Usuario cliente = v.getCliente();
        return ViajeDetalleConductorResponse.builder()
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
                .clienteId(cliente != null ? cliente.getId() : null)
                .clienteNombre(cliente != null ? cliente.getNombreCompleto() : null)
                .clienteApellidos(cliente != null ? cliente.getApellidosCompletos() : null)
                .clienteTelefono(cliente != null ? cliente.getTelefono() : null)
                .clienteEmail(cliente != null ? cliente.getEmail() : null)
                .build();
    }

    // ========================================================================
    // HISTORIAL PAGINADO
    // ========================================================================

    // Historial de viajes asignados al conductor. estado es opcional;
    // si null se muestran todos los viajes finalizados/cancelados/en curso.
    public PageResponse<ViajeResponse> historialViajes(Long conductorId,
                                                        Viaje.EstadoViaje estado,
                                                        LocalDateTime desde,
                                                        LocalDateTime hasta,
                                                        int page, int size) {
        List<Viaje.EstadoViaje> estados = estado != null
                ? List.of(estado)
                : List.of(Viaje.EstadoViaje.ACEPTADO,
                          Viaje.EstadoViaje.EN_CAMINO,
                          Viaje.EstadoViaje.EN_CURSO,
                          Viaje.EstadoViaje.FINALIZADO,
                          Viaje.EstadoViaje.CANCELADO);

        Pageable pageable = PageRequest.of(page, size);
        Page<Viaje> resultado = viajeRepository.findHistorialPorConductor(
                conductorId, estados, desde, hasta, pageable);

        return PageResponse.from(resultado, viajeService::mapToViajeResponse);
    }

    // Atajo: viajes "en proceso" del conductor (ACEPTADO|EN_CAMINO|EN_CURSO).
    public PageResponse<ViajeResponse> historialEnProceso(Long conductorId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        List<Viaje.EstadoViaje> estados = List.of(
                Viaje.EstadoViaje.ACEPTADO,
                Viaje.EstadoViaje.EN_CAMINO,
                Viaje.EstadoViaje.EN_CURSO
        );
        Page<Viaje> resultado = viajeRepository.findHistorialPorConductor(
                conductorId, estados, null, null, pageable);
        return PageResponse.from(resultado, viajeService::mapToViajeResponse);
    }

    // Historial de solicitudes recibidas por el conductor (con filtro opcional por estado).
    public PageResponse<SolicitudResponse> historialSolicitudes(Long conductorId,
                                                                 ViajeConductor.EstadoSolicitud estado,
                                                                 int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<ViajeConductor> resultado = viajeConductorRepository.findHistorialPorConductor(
                conductorId, estado, pageable);
        return PageResponse.from(resultado, this::mapToSolicitudResponse);
    }

    // ========================================================================
    // ESTADÍSTICAS DEL CONDUCTOR
    // ========================================================================

    public GananciasResponse gananciasDelDia(Long conductorId, LocalDate fecha) {
        LocalDateTime desde = fecha.atStartOfDay();
        LocalDateTime hasta = fecha.atTime(LocalTime.MAX);
        return calcularGanancias(conductorId, fecha.toString(), desde, hasta);
    }

    public GananciasResponse gananciasDelMes(Long conductorId, int anio, int mes) {
        YearMonth ym = YearMonth.of(anio, mes);
        LocalDateTime desde = ym.atDay(1).atStartOfDay();
        LocalDateTime hasta = ym.atEndOfMonth().atTime(LocalTime.MAX);
        String periodo = String.format("%04d-%02d", anio, mes);
        return calcularGanancias(conductorId, periodo, desde, hasta);
    }

    private GananciasResponse calcularGanancias(Long conductorId, String periodo,
                                                 LocalDateTime desde, LocalDateTime hasta) {
        BigDecimal total = viajeRepository.sumarGananciasPorConductor(conductorId, desde, hasta);
        long count = viajeRepository.contarViajesFinalizadosPorConductor(conductorId, desde, hasta);
        return GananciasResponse.builder()
                .periodo(periodo)
                .desde(desde)
                .hasta(hasta)
                .total(total != null ? total : BigDecimal.ZERO)
                .cantidadViajes(count)
                .build();
    }

    // Cantidad de viajes FINALIZADOS por el conductor en un día (su productividad).
    public long viajesDelDia(Long conductorId, LocalDate fecha) {
        LocalDateTime desde = fecha.atStartOfDay();
        LocalDateTime hasta = fecha.atTime(LocalTime.MAX);
        return viajeRepository.contarViajesFinalizadosPorConductor(conductorId, desde, hasta);
    }

    // Cantidad de viajes FINALIZADOS por el conductor en un mes.
    public long viajesDelMes(Long conductorId, int anio, int mes) {
        YearMonth ym = YearMonth.of(anio, mes);
        LocalDateTime desde = ym.atDay(1).atStartOfDay();
        LocalDateTime hasta = ym.atEndOfMonth().atTime(LocalTime.MAX);
        return viajeRepository.contarViajesFinalizadosPorConductor(conductorId, desde, hasta);
    }

    // ========================================================================
    // CALIFICAR AL CLIENTE (conductor → cliente)
    // ========================================================================

    @Transactional
    public CalificacionResponse calificarCliente(Long viajeId, Long conductorId,
                                                  CalificarViajeRequest req) {
        Viaje viaje = obtenerViajeDelConductor(viajeId, conductorId);

        if (viaje.getEstadoViaje() != Viaje.EstadoViaje.FINALIZADO) {
            throw new BusinessException(
                    "Solo se puede calificar un viaje FINALIZADO. Estado actual: "
                            + viaje.getEstadoViaje(),
                    HttpStatus.CONFLICT);
        }

        Usuario cliente = viaje.getCliente();
        if (cliente == null) {
            throw new BusinessException(
                    "El viaje no tiene un cliente asociado.",
                    HttpStatus.CONFLICT);
        }

        // Evitar doble calificación del mismo viaje por el mismo conductor
        boolean yaExiste = calificacionRepository.existsByViajeIdAndCalificadorIdAndTipoCalificacion(
                viajeId, conductorId, Calificacion.TipoCalificacion.CONDUCTOR_A_CLIENTE);
        if (yaExiste) {
            throw new BusinessException(
                    "Ya calificaste este viaje. No se permite calificar más de una vez.",
                    HttpStatus.CONFLICT);
        }

        Usuario conductorUsuario = viaje.getConductor();

        Calificacion calificacion = new Calificacion();
        calificacion.setViaje(viaje);
        calificacion.setCalificador(conductorUsuario);
        calificacion.setCalificado(cliente);
        calificacion.setTipoCalificacion(Calificacion.TipoCalificacion.CONDUCTOR_A_CLIENTE);
        calificacion.setPuntuacion(req.getPuntuacion());
        calificacion.setComentario(req.getComentario());
        calificacion.setFechaCalificacion(LocalDateTime.now());

        Calificacion guardada = calificacionRepository.save(calificacion);

        // Notificar al cliente que recibió una nueva calificación
        notificacionService.crear(
                cliente,
                viaje,
                Notificacion.TipoNotificacion.NUEVA_CALIFICACION,
                (conductorUsuario != null ? conductorUsuario.getNombreCompleto() : "El conductor")
                        + " te calificó con " + req.getPuntuacion() + "/5 en el viaje #"
                        + viaje.getId() + "."
        );

        return mapToCalificacionResponse(guardada);
    }

    // ========================================================================
    // CALIFICACIONES RECIBIDAS (visualización por el conductor)
    // ========================================================================

    // Listado paginado de calificaciones recibidas por el conductor desde clientes.
    public PageResponse<CalificacionResponse> obtenerCalificacionesRecibidas(
            Long conductorId, int page, int size) {
        Pageable pageable = PageRequest.of(page, size);
        Page<Calificacion> resultado = calificacionRepository.findByCalificadoIdAndTipo(
                conductorId, Calificacion.TipoCalificacion.CLIENTE_A_CONDUCTOR, pageable);
        return PageResponse.from(resultado, this::mapToCalificacionResponse);
    }

    // Resumen: promedio + total de calificaciones CLIENTE→CONDUCTOR recibidas.
    public PromedioCalificacionResponse obtenerPromedioCalificaciones(Long conductorId) {
        Double promedio = calificacionRepository.obtenerPromedioPorTipo(
                conductorId, Calificacion.TipoCalificacion.CLIENTE_A_CONDUCTOR);
        long total = calificacionRepository.countByCalificadoIdAndTipoCalificacion(
                conductorId, Calificacion.TipoCalificacion.CLIENTE_A_CONDUCTOR);
        return PromedioCalificacionResponse.builder()
                .promedio(promedio)
                .totalCalificaciones(total)
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

    // ========================================================================
    // Helpers de mapeo
    // ========================================================================

    private PerfilConductorResponse mapToPerfilResponse(Conductor c) {
        Usuario u = c.getUsuario();
        Automovil auto = c.getAutomovil();
        return PerfilConductorResponse.builder()
                .usuarioId(c.getUsuarioId())
                .nombreCompleto(u != null ? u.getNombreCompleto() : null)
                .apellidosCompletos(u != null ? u.getApellidosCompletos() : null)
                .fechaNacimiento(u != null ? u.getFechaNacimiento() : null)
                .nombreUsuario(u != null ? u.getNombreUsuario() : null)
                .tipoDocumento(u != null ? u.getTipoDocumento() : null)
                .numeroDocumento(u != null ? u.getNumeroDocumento() : null)
                .genero(u != null ? u.getGenero() : null)
                .telefono(u != null ? u.getTelefono() : null)
                .email(u != null ? u.getEmail() : null)
                .licencia(c.getLicencia())
                .tipoLicencia(c.getTipoLicencia())
                .disponibilidad(c.getDisponibilidad())
                .activo(c.getActivo() == null ? Boolean.TRUE : c.getActivo())
                .marcaVehiculo(auto != null ? auto.getMarca() : null)
                .modeloVehiculo(auto != null ? auto.getModelo() : null)
                .placaVehiculo(auto != null ? auto.getPlaca() : null)
                .capacidadMaxima(auto != null ? auto.getCapacidadMaxima() : 0)
                .categoriaVehiculo(auto != null && auto.getCategoria() != null
                        ? auto.getCategoria().getNombre() : null)
                .build();
    }

    private SolicitudResponse mapToSolicitudResponse(ViajeConductor vc) {
        Viaje v = vc.getViaje();
        return SolicitudResponse.builder()
                .solicitudId(vc.getId())
                .viajeId(v != null ? v.getId() : null)
                .estado(vc.getEstado())
                .clienteId(v != null && v.getCliente() != null ? v.getCliente().getId() : null)
                .clienteNombre(v != null && v.getCliente() != null
                        ? v.getCliente().getNombreCompleto() : null)
                .cantidadPasajeros(v != null ? v.getCantidadPasajeros() : 0)
                .origenLat(v != null ? v.getOrigenLat() : null)
                .origenLng(v != null ? v.getOrigenLng() : null)
                .destinoLat(v != null ? v.getDestinoLat() : null)
                .destinoLng(v != null ? v.getDestinoLng() : null)
                .precioCalculado(v != null ? v.getPrecioCalculado() : null)
                .fechaOferta(vc.getFechaOferta())
                .fechaRespuesta(vc.getFechaRespuesta())
                .fechaExpiracion(vc.getFechaExpiracion())
                .build();
    }
}

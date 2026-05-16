package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.SolicitarViajeRequest;
import com.GAV.gav.DTO.Response.ViajeResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.List;

// Gestiona el ciclo de vida de los viajes y contiene la lógica central del algoritmo FIFO.
//
// FLUJO FIFO:
//   1. Cliente solicita viaje → Viaje creado en estado SOLICITADO con precio calculado
//   2. Sistema busca conductores disponibles ordenados por fechaDisponibleDesde ASC (FIFO)
//   3. Se filtra por capacidad del vehículo y se excluyen conductores que ya rechazaron/expiraron
//   4. Se crea ViajeConductor(PENDIENTE) para el primer conductor de la cola + Notificación
//   5. Conductor tiene SEGUNDOS_EXPIRACION para responder
//   6. Si no responde → scheduler marca como EXPIRADO → siguiente en cola FIFO
//   7. Si acepta → viaje queda en estado ACEPTADO, conductor sale del pool
//   8. Si no hay conductores → viaje queda en BUSCANDO_CONDUCTOR hasta que uno se conecte
@Service
@RequiredArgsConstructor
public class ViajeService {

    // Tiempo máximo (segundos) para que un conductor responda una solicitud antes de expirar
    private static final int SEGUNDOS_EXPIRACION = 30;

    private final ViajeRepository viajeRepository;
    private final UsuarioRepository usuarioRepository;
    private final ConductorRepository conductorRepository;
    private final ViajeConductorRepository viajeConductorRepository;
    private final TarifaRepository tarifaRepository;
    private final NotificacionService notificacionService;
    private final LugarRepository lugarRepository;

    // El cliente solicita un viaje. Se crea el registro, se calcula el precio
    // y se dispara la asignación FIFO inmediatamente.
    @Transactional
    public ViajeResponse solicitarViaje(SolicitarViajeRequest request, Long clienteId) {
        Usuario cliente = usuarioRepository.findById(clienteId)
                .orElseThrow(() -> new BusinessException(
                        "Cliente no encontrado: " + clienteId, HttpStatus.NOT_FOUND));

        // Calcular precio con la tarifa activa actual
        BigDecimal precio = calcularPrecio(request.getDistanciaKm(), request.getDuracionMin());

        Viaje viaje = new Viaje();
        viaje.setCliente(cliente);
        viaje.setCantidadPasajeros(request.getCantidadPasajeros());
        viaje.setOrigenLat(request.getOrigenLat());
        viaje.setOrigenLng(request.getOrigenLng());
        viaje.setDestinoLat(request.getDestinoLat());
        viaje.setDestinoLng(request.getDestinoLng());
        viaje.setEstadoViaje(Viaje.EstadoViaje.SOLICITADO);
        viaje.setFechaSolicitud(LocalDateTime.now());
        viaje.setPrecioCalculado(precio);
        // Vincular el destino a un lugar conocido del catálogo (si cae dentro de su radio).
        viaje.setLugarDestino(
                matchLugarDestino(request.getDestinoLat(), request.getDestinoLng()));
        Viaje viajeGuardado = viajeRepository.save(viaje);

        // Disparar la asignación FIFO en la misma transacción
        asignarPrimerConductorFIFO(viajeGuardado);

        return mapToViajeResponse(
                viajeRepository.findById(viajeGuardado.getId()).orElse(viajeGuardado));
    }

    // Cálculo de precio:
    //   precio = (precioBase + precioPorKm * km + precioPorMinuto * min) * multiplicadorDinamico
    // Si no hay tarifa activa configurada, falla con un 500 explícito.
    private BigDecimal calcularPrecio(BigDecimal distanciaKm, int duracionMin) {
        Tarifa tarifa = tarifaRepository.findByTarifaActiva()
                .orElseThrow(() -> new BusinessException(
                        "No hay una tarifa activa configurada. Contacte al administrador.",
                        HttpStatus.INTERNAL_SERVER_ERROR));

        BigDecimal porKm = tarifa.getPrecioPorKm().multiply(distanciaKm);
        BigDecimal porMin = tarifa.getPrecioPorMinuto()
                .multiply(BigDecimal.valueOf(duracionMin));
        BigDecimal subtotal = tarifa.getPrecioBase().add(porKm).add(porMin);

        BigDecimal multiplicador = tarifa.getMultiplicadorDinamico() != null
                ? tarifa.getMultiplicadorDinamico() : BigDecimal.ONE;

        return subtotal.multiply(multiplicador).setScale(2, RoundingMode.HALF_UP);
    }

    // Empareja el destino (lat,lng) con el primer lugar activo del catálogo cuyo
    // radio contenga el punto. Devuelve null si ninguno coincide.
    private Lugar matchLugarDestino(BigDecimal lat, BigDecimal lng) {
        if (lat == null || lng == null) {
            return null;
        }
        double dLat = lat.doubleValue();
        double dLng = lng.doubleValue();
        return lugarRepository.findActivos().stream()
                .filter(l -> l.getLat() != null && l.getLng() != null)
                .filter(l -> {
                    double dist = haversineMetros(dLat, dLng,
                            l.getLat().doubleValue(), l.getLng().doubleValue());
                    int radio = l.getRadioMetros() != null ? l.getRadioMetros() : 200;
                    return dist <= radio;
                })
                .findFirst()
                .orElse(null);
    }

    // Distancia en metros entre dos coordenadas (Haversine).
    private static double haversineMetros(double lat1, double lng1,
                                          double lat2, double lng2) {
        double radioTierraM = 6_371_000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return radioTierraM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    // Primera asignación: no hay conductores excluidos aún, solo filtrar por capacidad
    private void asignarPrimerConductorFIFO(Viaje viaje) {
        viaje.setEstadoViaje(Viaje.EstadoViaje.BUSCANDO_CONDUCTOR);
        viajeRepository.save(viaje);

        List<Conductor> candidatos = conductorRepository
                .findPrimerConductorFIFO(viaje.getCantidadPasajeros());

        if (candidatos.isEmpty()) {
            // No hay conductores disponibles; el viaje queda en BUSCANDO_CONDUCTOR.
            // El scheduler o una llamada futura a asignarSiguienteConductorFIFO lo retomará.
            return;
        }

        crearSolicitudPendiente(viaje, candidatos.get(0));
    }

    // Asignación de siguiente conductor en FIFO tras rechazo o expiración.
    // Excluye conductores que ya rechazaron o expiraron para este viaje específico.
    @Transactional
    public void asignarSiguienteConductorFIFO(Viaje viaje) {
        List<ViajeConductor.EstadoSolicitud> excluidos = List.of(
                ViajeConductor.EstadoSolicitud.RECHAZADO,
                ViajeConductor.EstadoSolicitud.EXPIRADO
        );

        List<Conductor> candidatos = conductorRepository
                .findSiguienteConductorFIFO(viaje.getCantidadPasajeros(), viaje.getId(), excluidos);

        if (candidatos.isEmpty()) {
            // Cola agotada: nadie disponible que no haya rechazado/expirado ya
            viaje.setEstadoViaje(Viaje.EstadoViaje.BUSCANDO_CONDUCTOR);
            viajeRepository.save(viaje);
            return;
        }

        crearSolicitudPendiente(viaje, candidatos.get(0));
    }

    // Crea el registro ViajeConductor(PENDIENTE) y notifica al conductor.
    private void crearSolicitudPendiente(Viaje viaje, Conductor conductor) {
        LocalDateTime ahora = LocalDateTime.now();
        ViajeConductor solicitud = new ViajeConductor(
                viaje,
                conductor,
                ViajeConductor.EstadoSolicitud.PENDIENTE,
                ahora,
                ahora.plusSeconds(SEGUNDOS_EXPIRACION)
        );
        viajeConductorRepository.save(solicitud);

        // Notificar al conductor que tiene una nueva solicitud por aceptar/rechazar.
        notificacionService.crear(
                conductor.getUsuario(),
                viaje,
                Notificacion.TipoNotificacion.NUEVA_SOLICITUD,
                "Nueva solicitud de viaje #" + viaje.getId()
                        + " — tienes " + SEGUNDOS_EXPIRACION + "s para responder."
        );
    }

    // Scheduler que corre cada 10 segundos para detectar solicitudes que expiraron sin respuesta.
    // Marca como EXPIRADO y avanza al siguiente conductor en la cola FIFO automáticamente.
    @Scheduled(fixedDelay = 10_000)
    @Transactional
    public void verificarSolicitudesExpiradas() {
        List<ViajeConductor> expiradas = viajeConductorRepository
                .findSolicitudesExpiradas(LocalDateTime.now());

        for (ViajeConductor solicitud : expiradas) {
            solicitud.setEstado(ViajeConductor.EstadoSolicitud.EXPIRADO);
            solicitud.setFechaRespuesta(LocalDateTime.now());
            viajeConductorRepository.save(solicitud);

            Viaje viaje = solicitud.getViaje();
            // Solo avanzar si el viaje aún está buscando conductor
            if (viaje.getEstadoViaje() == Viaje.EstadoViaje.BUSCANDO_CONDUCTOR
                    || viaje.getEstadoViaje() == Viaje.EstadoViaje.SOLICITADO) {
                asignarSiguienteConductorFIFO(viaje);
            }
        }
    }

    // Consultas de viajes
    public List<ViajeResponse> obtenerViajesCliente(Long clienteId) {
        return viajeRepository.findByClienteId(clienteId)
                .stream()
                .map(this::mapToViajeResponse)
                .toList();
    }

    public List<ViajeResponse> obtenerViajesPendientes() {
        return viajeRepository.findViajesPendientes()
                .stream()
                .map(this::mapToViajeResponse)
                .toList();
    }

    public ViajeResponse obtenerViajePorId(Long viajeId) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));
        return mapToViajeResponse(viaje);
    }

    // Cancelación por parte del CLIENTE (antes de EN_CURSO).
    // Si ya había un conductor asignado, este vuelve al pool FIFO y recibe notificación.
    // Si había una solicitud PENDIENTE en cola, se marca como EXPIRADA para que no responda.
    @Transactional
    public ViajeResponse cancelarPorCliente(Long viajeId, Long clienteId, String motivo) {
        Viaje viaje = viajeRepository.findById(viajeId)
                .orElseThrow(() -> new BusinessException(
                        "Viaje no encontrado: " + viajeId, HttpStatus.NOT_FOUND));

        // Validar ownership: solo el cliente que solicitó el viaje puede cancelarlo
        if (viaje.getCliente() == null || !viaje.getCliente().getId().equals(clienteId)) {
            throw new BusinessException(
                    "El cliente " + clienteId + " no es el solicitante de este viaje.",
                    HttpStatus.FORBIDDEN);
        }

        if (viaje.getEstadoViaje() == Viaje.EstadoViaje.EN_CURSO
                || viaje.getEstadoViaje() == Viaje.EstadoViaje.FINALIZADO
                || viaje.getEstadoViaje() == Viaje.EstadoViaje.CANCELADO) {
            throw new BusinessException(
                    "No se puede cancelar un viaje en estado: " + viaje.getEstadoViaje(),
                    HttpStatus.CONFLICT);
        }

        // Si había un conductor asignado (estados ACEPTADO o EN_CAMINO), regresarlo al pool FIFO
        Usuario conductorUsuario = viaje.getConductor();
        if (conductorUsuario != null) {
            Conductor conductor = conductorRepository.findByUsuarioId(conductorUsuario.getId())
                    .orElseThrow(() -> new BusinessException(
                            "Conductor no encontrado: " + conductorUsuario.getId(),
                            HttpStatus.NOT_FOUND));
            conductor.setDisponibilidad(true);
            conductor.setFechaDisponibleDesde(LocalDateTime.now());
            conductorRepository.save(conductor);

            // Notificar al conductor asignado que el cliente canceló
            notificacionService.crear(
                    conductorUsuario,
                    viaje,
                    Notificacion.TipoNotificacion.VIAJE_CANCELADO,
                    "El cliente canceló el viaje #" + viaje.getId()
                            + (motivo != null && !motivo.isBlank() ? " — Motivo: " + motivo : "")
            );
        }

        // Si había una solicitud PENDIENTE en la cola FIFO, marcarla como EXPIRADA
        // para evitar que el conductor reciba/acepte una solicitud sobre un viaje cancelado.
        viajeConductorRepository.findByViajeIdAndEstado(
                viajeId, ViajeConductor.EstadoSolicitud.PENDIENTE)
                .ifPresent(solicitud -> {
                    solicitud.setEstado(ViajeConductor.EstadoSolicitud.EXPIRADO);
                    solicitud.setFechaRespuesta(LocalDateTime.now());
                    viajeConductorRepository.save(solicitud);
                });

        viaje.setEstadoViaje(Viaje.EstadoViaje.CANCELADO);
        viajeRepository.save(viaje);

        return mapToViajeResponse(viaje);
    }

    // Mapea la entidad Viaje al DTO de respuesta aplanando las referencias
    public ViajeResponse mapToViajeResponse(Viaje v) {
        ViajeResponse.ViajeResponseBuilder builder = ViajeResponse.builder()
                .id(v.getId())
                .cantidadPasajeros(v.getCantidadPasajeros())
                .origenLat(v.getOrigenLat())
                .origenLng(v.getOrigenLng())
                .destinoLat(v.getDestinoLat())
                .destinoLng(v.getDestinoLng())
                .estadoViaje(v.getEstadoViaje())
                .precioCalculado(v.getPrecioCalculado())
                .fechaSolicitud(v.getFechaSolicitud())
                .fechaInicio(v.getFechaInicio())
                .fechaFinalizacion(v.getFechaFinalizacion());

        if (v.getCliente() != null) {
            builder.clienteId(v.getCliente().getId())
                   .clienteNombre(v.getCliente().getNombreCompleto());
        }

        if (v.getConductor() != null) {
            builder.conductorId(v.getConductor().getId())
                   .conductorNombre(v.getConductor().getNombreCompleto());
        }

        return builder.build();
    }
}

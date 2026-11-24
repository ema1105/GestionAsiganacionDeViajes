package com.GAV.gav.Repository;

import com.GAV.gav.Model.ViajeConductor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ViajeConductorRepository extends JpaRepository<ViajeConductor, Long> {

    List<ViajeConductor> findByViajeId(Long viajeId);

    List<ViajeConductor> findByConductorUsuarioId(Long usuarioId);

    Optional<ViajeConductor> findByViajeIdAndConductorUsuarioId(Long viajeId, Long conductorId);

    // NUEVO: busca la solicitud PENDIENTE activa de un viaje.
    // En el FIFO solo hay una solicitud PENDIENTE a la vez por viaje.
    Optional<ViajeConductor> findByViajeIdAndEstado(Long viajeId, ViajeConductor.EstadoSolicitud estado);

    // NUEVO: consulta para el scheduler que revisa expiraciones.
    // Trae todas las solicitudes que siguen PENDIENTE pero ya superaron su fechaExpiracion.
    // El scheduler en ViajeService las procesa periódicamente para avanzar el FIFO.
    @Query("""
        SELECT vc FROM ViajeConductor vc
        WHERE vc.estado = com.GAV.gav.Model.ViajeConductor.EstadoSolicitud.PENDIENTE
        AND vc.fechaExpiracion < :ahora
    """)
    List<ViajeConductor> findSolicitudesExpiradas(@Param("ahora") LocalDateTime ahora);

    // Solicitudes PENDIENTE cuyo conductor se desconectó (cerró la app): se expiran
    // de inmediato en vez de esperar los 30 s completos.
    @Query("""
        SELECT vc FROM ViajeConductor vc
        WHERE vc.estado = com.GAV.gav.Model.ViajeConductor.EstadoSolicitud.PENDIENTE
        AND (vc.conductor.ultimaConexion IS NULL OR vc.conductor.ultimaConexion < :conectadoDesde)
    """)
    List<ViajeConductor> findPendientesDeConductoresDesconectados(
            @Param("conectadoDesde") LocalDateTime conectadoDesde);

    // Historial paginado de solicitudes recibidas por un conductor, con filtro opcional por estado.
    @Query("""
        SELECT vc FROM ViajeConductor vc
        WHERE vc.conductor.usuarioId = :conductorId
        AND (:estado IS NULL OR vc.estado = :estado)
        ORDER BY vc.fechaOferta DESC
    """)
    Page<ViajeConductor> findHistorialPorConductor(
            @Param("conductorId") Long conductorId,
            @Param("estado") ViajeConductor.EstadoSolicitud estado,
            Pageable pageable
    );

    // Indica si hubo ofertas previas para este viaje con cualquiera de los estados dados.
    // Lo usa el FIFO para detectar que recorrió toda la cola sin aceptación.
    boolean existsByViajeIdAndEstadoIn(Long viajeId, List<ViajeConductor.EstadoSolicitud> estados);

    // Borra las ofertas de un viaje que estén en los estados dados.
    // Lo usa el FIFO para "reiniciar el ciclo" tras recorrer toda la cola
    // sin que nadie aceptara: limpia los RECHAZADO/EXPIRADO de este viaje
    // y permite que los mismos conductores vuelvan a recibir la solicitud.
    @Modifying
    @Transactional
    long deleteByViajeIdAndEstadoIn(Long viajeId, List<ViajeConductor.EstadoSolicitud> estados);
}

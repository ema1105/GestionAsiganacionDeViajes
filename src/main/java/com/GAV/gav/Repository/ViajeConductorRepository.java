package com.GAV.gav.Repository;

import com.GAV.gav.Model.ViajeConductor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

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
}

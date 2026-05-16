package com.GAV.gav.Repository;

import com.GAV.gav.Model.Viaje;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ViajeRepository extends JpaRepository<Viaje, Long> {

    List<Viaje> findByClienteId(Long clienteId);

    List<Viaje> findByConductorId(Long conductorId);

    List<Viaje> findByEstadoViaje(Viaje.EstadoViaje estado);

    @Query("""
        SELECT v FROM Viaje v
        WHERE v.estadoViaje IN ('SOLICITADO', 'BUSCANDO_CONDUCTOR')
    """)
    List<Viaje> findViajesPendientes();

    Page<Viaje> findByClienteId(Long clienteId, Pageable pageable);

    // Listado admin paginado con filtros opcionales (NULL = sin filtro).
    @Query("""
        SELECT v FROM Viaje v
        WHERE (:estado IS NULL OR v.estadoViaje = :estado)
        AND (:clienteId IS NULL OR v.cliente.id = :clienteId)
        AND (:conductorId IS NULL OR v.conductor.id = :conductorId)
        AND (:desde IS NULL OR v.fechaSolicitud >= :desde)
        AND (:hasta IS NULL OR v.fechaSolicitud <= :hasta)
        ORDER BY v.fechaSolicitud DESC
    """)
    Page<Viaje> findConFiltros(
            @Param("estado") Viaje.EstadoViaje estado,
            @Param("clienteId") Long clienteId,
            @Param("conductorId") Long conductorId,
            @Param("desde") LocalDateTime desde,
            @Param("hasta") LocalDateTime hasta,
            Pageable pageable
    );

    // Suma de precioCalculado para viajes FINALIZADOS en un rango.
    // Devuelve 0 (no NULL) cuando no hay registros gracias a COALESCE.
    @Query("""
        SELECT COALESCE(SUM(v.precioCalculado), 0) FROM Viaje v
        WHERE v.estadoViaje = com.GAV.gav.Model.Viaje$EstadoViaje.FINALIZADO
        AND v.fechaFinalizacion BETWEEN :desde AND :hasta
    """)
    BigDecimal sumarGanancias(@Param("desde") LocalDateTime desde,
                              @Param("hasta") LocalDateTime hasta);

    // Cantidad de viajes FINALIZADOS en un rango.
    @Query("""
        SELECT COUNT(v) FROM Viaje v
        WHERE v.estadoViaje = com.GAV.gav.Model.Viaje$EstadoViaje.FINALIZADO
        AND v.fechaFinalizacion BETWEEN :desde AND :hasta
    """)
    long contarViajesFinalizados(@Param("desde") LocalDateTime desde,
                                 @Param("hasta") LocalDateTime hasta);

    // Conteo de viajes solicitados por día en un rango.
    // Devuelve filas (java.sql.Date, long) listas para mapear a DTO en el service.
    @Query(value = """
        SELECT DATE(v.fecha_solicitud) AS fecha, COUNT(*) AS cantidad
        FROM viaje v
        WHERE v.fecha_solicitud BETWEEN :desde AND :hasta
        GROUP BY DATE(v.fecha_solicitud)
        ORDER BY DATE(v.fecha_solicitud) ASC
    """, nativeQuery = true)
    List<Object[]> contarViajesPorDia(@Param("desde") LocalDateTime desde,
                                      @Param("hasta") LocalDateTime hasta);

    // ====== Conductor: historial paginado de viajes asignados ======
    // estados debe ser una lista no-vacía con los estados a incluir.
    @Query("""
        SELECT v FROM Viaje v
        WHERE v.conductor.id = :conductorId
        AND v.estadoViaje IN :estados
        AND (:desde IS NULL OR v.fechaSolicitud >= :desde)
        AND (:hasta IS NULL OR v.fechaSolicitud <= :hasta)
        ORDER BY v.fechaSolicitud DESC
    """)
    Page<Viaje> findHistorialPorConductor(
            @Param("conductorId") Long conductorId,
            @Param("estados") List<Viaje.EstadoViaje> estados,
            @Param("desde") LocalDateTime desde,
            @Param("hasta") LocalDateTime hasta,
            Pageable pageable
    );

    // Viaje activo único del conductor (debería ser a lo sumo uno).
    @Query("""
        SELECT v FROM Viaje v
        WHERE v.conductor.id = :conductorId
        AND v.estadoViaje IN ('ACEPTADO', 'EN_CAMINO', 'EN_CURSO')
        ORDER BY v.fechaInicio DESC
    """)
    List<Viaje> findViajeActivoDelConductor(@Param("conductorId") Long conductorId);

    // ====== Conductor: estadísticas filtradas por conductorId ======
    @Query("""
        SELECT COALESCE(SUM(v.precioCalculado), 0) FROM Viaje v
        WHERE v.conductor.id = :conductorId
        AND v.estadoViaje = com.GAV.gav.Model.Viaje$EstadoViaje.FINALIZADO
        AND v.fechaFinalizacion BETWEEN :desde AND :hasta
    """)
    BigDecimal sumarGananciasPorConductor(@Param("conductorId") Long conductorId,
                                          @Param("desde") LocalDateTime desde,
                                          @Param("hasta") LocalDateTime hasta);

    @Query("""
        SELECT COUNT(v) FROM Viaje v
        WHERE v.conductor.id = :conductorId
        AND v.estadoViaje = com.GAV.gav.Model.Viaje$EstadoViaje.FINALIZADO
        AND v.fechaFinalizacion BETWEEN :desde AND :hasta
    """)
    long contarViajesFinalizadosPorConductor(@Param("conductorId") Long conductorId,
                                              @Param("desde") LocalDateTime desde,
                                              @Param("hasta") LocalDateTime hasta);

    // ====== Chatbot: lugares más solicitados (históricos) ======
    // Cuenta viajes FINALIZADOS agrupados por lugar destino conocido.
    // Devuelve filas [Lugar, Long]; el limite se pasa vía Pageable.
    @Query("""
        SELECT v.lugarDestino, COUNT(v) FROM Viaje v
        WHERE v.estadoViaje = com.GAV.gav.Model.Viaje$EstadoViaje.FINALIZADO
        AND v.lugarDestino IS NOT NULL
        GROUP BY v.lugarDestino
        ORDER BY COUNT(v) DESC
    """)
    List<Object[]> lugaresMasSolicitados(Pageable pageable);
}

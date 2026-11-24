package com.GAV.gav.Repository;

import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.ViajeConductor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ConductorRepository extends JpaRepository<Conductor, Long> {

    Optional<Conductor> findByUsuarioId(Long usuarioId);

    // CAMBIO: query original actualizada para mantener consistencia
    @Query("SELECT c FROM Conductor c WHERE c.disponibilidad = true")
    List<Conductor> findByConductoresDisponibles();

    // FIFO: conductores activos (NULL tratado como true), disponibles, CONECTADOS
    // (señal de la app desde :conectadoDesde), con capacidad, que NO han rechazado
    // ni expirado este viaje. Ordenados FIFO.
    @Query("""
        SELECT c FROM Conductor c
        WHERE c.disponibilidad = true
        AND (c.activo IS NULL OR c.activo = true)
        AND c.ultimaConexion >= :conectadoDesde
        AND c.automovil.capacidadMaxima >= :cantidadPasajeros
        AND c NOT IN (
            SELECT vc.conductor FROM ViajeConductor vc
            WHERE vc.viaje.id = :viajeId
            AND vc.estado IN :estadosExcluidos
        )
        ORDER BY c.fechaDisponibleDesde ASC
    """)
    List<Conductor> findSiguienteConductorFIFO(
            @Param("conectadoDesde") LocalDateTime conectadoDesde,
            @Param("cantidadPasajeros") int cantidadPasajeros,
            @Param("viajeId") Long viajeId,
            @Param("estadosExcluidos") List<ViajeConductor.EstadoSolicitud> estadosExcluidos
    );

    // Primera asignación: conductores activos, disponibles, conectados, con capacidad. Orden FIFO.
    @Query("""
        SELECT c FROM Conductor c
        WHERE c.disponibilidad = true
        AND (c.activo IS NULL OR c.activo = true)
        AND c.ultimaConexion >= :conectadoDesde
        AND c.automovil.capacidadMaxima >= :cantidadPasajeros
        ORDER BY c.fechaDisponibleDesde ASC
    """)
    List<Conductor> findPrimerConductorFIFO(
            @Param("conectadoDesde") LocalDateTime conectadoDesde,
            @Param("cantidadPasajeros") int cantidadPasajeros);

    // Mapa "Flota en vivo" (admin): conductores habilitados, conectados y con posición.
    // Incluye disponibles y en viaje (disponibilidad no se filtra).
    @Query("""
        SELECT c FROM Conductor c
        WHERE (c.activo IS NULL OR c.activo = true)
        AND c.ultimaConexion >= :conectadoDesde
        AND c.ultimaLat IS NOT NULL
        AND c.ultimaLng IS NOT NULL
        ORDER BY c.usuarioId ASC
    """)
    List<Conductor> findConectadosConUbicacion(@Param("conectadoDesde") LocalDateTime conectadoDesde);

    // ¿Hay al menos un conductor disponible y conectado? (evita trabajo inútil del scheduler)
    @Query("""
        SELECT COUNT(c) > 0 FROM Conductor c
        WHERE c.disponibilidad = true
        AND (c.activo IS NULL OR c.activo = true)
        AND c.ultimaConexion >= :conectadoDesde
    """)
    boolean existeConductorConectado(@Param("conectadoDesde") LocalDateTime conectadoDesde);

    // Latido de conexión: lo llama cada consulta de la app del conductor
    // (polling de solicitudes cada ~6 s y heartbeat GPS).
    @Modifying
    @Query("UPDATE Conductor c SET c.ultimaConexion = :ahora WHERE c.usuarioId = :usuarioId")
    int marcarConectado(@Param("usuarioId") Long usuarioId, @Param("ahora") LocalDateTime ahora);

    // Listado admin con filtros opcionales (NULL = sin filtro).
    // incluirInactivos: si false, excluye conductores con activo=false.
    @Query("""
        SELECT c FROM Conductor c
        WHERE (:disponibilidad IS NULL OR c.disponibilidad = :disponibilidad)
        AND (:tipoLicencia IS NULL OR c.tipoLicencia = :tipoLicencia)
        AND (:incluirInactivos = true OR c.activo IS NULL OR c.activo = true)
        ORDER BY c.usuarioId ASC
    """)
    List<Conductor> findConFiltros(
            @Param("disponibilidad") Boolean disponibilidad,
            @Param("tipoLicencia") Conductor.TipoLicencia tipoLicencia,
            @Param("incluirInactivos") boolean incluirInactivos
    );

    // Verifica que el conductor existe y está activo (NULL como true).
    @Query("""
        SELECT COUNT(c) > 0 FROM Conductor c
        WHERE c.usuarioId = :usuarioId
        AND (c.activo IS NULL OR c.activo = true)
    """)
    boolean existsByUsuarioIdAndActivoTrue(@Param("usuarioId") Long usuarioId);
}

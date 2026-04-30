package com.GAV.gav.Repository;

import com.GAV.gav.Model.Conductor;
import com.GAV.gav.Model.ViajeConductor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ConductorRepository extends JpaRepository<Conductor, Long> {

    List<Conductor> findByDisponibilidadTrue();

    Optional<Conductor> findByUsuarioId(Long usuarioId);

    // CAMBIO: query original actualizada para mantener consistencia
    @Query("SELECT c FROM Conductor c WHERE c.disponibilidad = true")
    List<Conductor> findByConductoresDisponibles();

    // NUEVO: consulta principal del algoritmo FIFO.
    // Devuelve conductores disponibles que:
    //   1. Tienen capacidad suficiente para los pasajeros solicitados
    //   2. NO han rechazado ni expirado para este viaje específico (no reintentar)
    //   3. Ordenados por fechaDisponibleDesde ASC → el que lleva más tiempo esperando primero
    @Query("""
        SELECT c FROM Conductor c
        WHERE c.disponibilidad = true
        AND c.automovil.capacidadMaxima >= :cantidadPasajeros
        AND c NOT IN (
            SELECT vc.conductor FROM ViajeConductor vc
            WHERE vc.viaje.Id = :viajeId
            AND vc.estado IN :estadosExcluidos
        )
        ORDER BY c.fechaDisponibleDesde ASC
    """)
    List<Conductor> findSiguienteConductorFIFO(
            @Param("cantidadPasajeros") int cantidadPasajeros,
            @Param("viajeId") Long viajeId,
            @Param("estadosExcluidos") List<ViajeConductor.EstadoSolicitud> estadosExcluidos
    );

    // NUEVO: para la primera asignación (viaje recién creado, sin intentos previos)
    // No necesita excluir nadie, solo filtra por capacidad y disponibilidad
    @Query("""
        SELECT c FROM Conductor c
        WHERE c.disponibilidad = true
        AND c.automovil.capacidadMaxima >= :cantidadPasajeros
        ORDER BY c.fechaDisponibleDesde ASC
    """)
    List<Conductor> findPrimerConductorFIFO(@Param("cantidadPasajeros") int cantidadPasajeros);
}

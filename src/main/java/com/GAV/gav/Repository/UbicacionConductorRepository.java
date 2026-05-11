package com.GAV.gav.Repository;

import com.GAV.gav.Model.UbicacionConductor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UbicacionConductorRepository extends JpaRepository<UbicacionConductor, Long> {

    // Última ubicación reportada por un conductor específico.
    Optional<UbicacionConductor> findTopByConductorUsuarioIdOrderByFechaDesc(Long conductorId);

    // Última ubicación de cada conductor disponible y activo (subquery sobre fecha máxima).
    // El service luego filtra por radio con Haversine en Java.
    @Query("""
        SELECT u FROM UbicacionConductor u
        WHERE u.fecha = (
            SELECT MAX(u2.fecha) FROM UbicacionConductor u2
            WHERE u2.conductor = u.conductor
        )
        AND u.conductor.disponibilidad = true
        AND (u.conductor.activo IS NULL OR u.conductor.activo = true)
    """)
    List<UbicacionConductor> findUltimaUbicacionDeDisponibles();
}

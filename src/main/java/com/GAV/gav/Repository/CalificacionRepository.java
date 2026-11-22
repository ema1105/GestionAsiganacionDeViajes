package com.GAV.gav.Repository;

import com.GAV.gav.Model.Calificacion;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CalificacionRepository extends JpaRepository<Calificacion, Long> {

    List<Calificacion> findByCalificadoId(Long usuarioId);

    // Promedio general de calificaciones recibidas por un usuario (sin distinguir tipo).
    @Query("""
        SELECT AVG(c.puntuacion) FROM Calificacion c
        WHERE c.calificado.id = :usuarioId
    """)
    Double obtenerPromedioCalificacion(@Param("usuarioId") Long usuarioId);

    // Listado paginado de calificaciones recibidas por un usuario en una dirección específica.
    @Query("""
        SELECT c FROM Calificacion c
        WHERE c.calificado.id = :usuarioId
        AND c.tipoCalificacion = :tipo
        ORDER BY c.fechaCalificacion DESC
    """)
    Page<Calificacion> findByCalificadoIdAndTipo(
            @Param("usuarioId") Long usuarioId,
            @Param("tipo") Calificacion.TipoCalificacion tipo,
            Pageable pageable
    );

    // Promedio recibido por un usuario en una dirección específica.
    @Query("""
        SELECT AVG(c.puntuacion) FROM Calificacion c
        WHERE c.calificado.id = :usuarioId
        AND c.tipoCalificacion = :tipo
    """)
    Double obtenerPromedioPorTipo(
            @Param("usuarioId") Long usuarioId,
            @Param("tipo") Calificacion.TipoCalificacion tipo
    );

    // Conteo total de calificaciones recibidas por un usuario en una dirección.
    long countByCalificadoIdAndTipoCalificacion(
            Long usuarioId,
            Calificacion.TipoCalificacion tipoCalificacion
    );

    // Evita doble calificación: el mismo calificador no puede calificar dos veces
    // el mismo viaje en la misma dirección.
    boolean existsByViajeIdAndCalificadorIdAndTipoCalificacion(
            Long viajeId,
            Long calificadorId,
            Calificacion.TipoCalificacion tipoCalificacion
    );
}

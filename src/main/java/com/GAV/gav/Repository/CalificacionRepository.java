package com.GAV.gav.Repository;

import com.GAV.gav.Model.Calificacion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface CalificacionRepository extends JpaRepository<Calificacion, Long> {

    List<Calificacion> findByCalificadoId(Long usuarioId);

    /*
    * Promedio de califiaciones de un usuario
    * findBy... no soporta agregaciones
    * */
    @Query("""
        SELECT AVG(c.puntuacion) FROM Calificacion c
        WHERE c.calificado.id = :usuarioId
    """)
    Double obtenerPromedioCalificacion(Long usuarioId);

}

package com.GAV.gav.Repository;

import com.GAV.gav.Model.Tarifa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TarifaRepository extends JpaRepository<Tarifa, Long> {

    /*
     * Devuelve la primera tarifa activa cuyo rango fechaInicio..fechaFin contenga el momento actual.
     * Las fechas son NULLABLE: una tarifa sin fechaInicio/fechaFin se considera siempre vigente.
     */
    @Query("""
            SELECT t FROM Tarifa t
            WHERE t.activo = true
            AND (t.fechaInicio IS NULL OR t.fechaInicio <= CURRENT_TIMESTAMP)
            AND (t.fechaFin IS NULL OR t.fechaFin >= CURRENT_TIMESTAMP)
            ORDER BY t.fechaInicio DESC
            """)
    java.util.List<Tarifa> findTarifasActivas();

    default Optional<Tarifa> findByTarifaActiva() {
        return findTarifasActivas().stream().findFirst();
    }
}

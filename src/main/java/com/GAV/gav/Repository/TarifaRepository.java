package com.GAV.gav.Repository;

import com.GAV.gav.Model.Tarifa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TarifaRepository extends JpaRepository<Tarifa, Long> {

    /*
    * validar tarifas activas o viegentes del momento
    */
    @Query("""
            SELECT t FROM Tarifa t
            WHERE t.activo = true
            AND CURRENT_TIMESTAMP BETWEEN t.fechaInicio AND t.fechaFin
            """)
    Optional<Tarifa>findByTarifaActiva();
}

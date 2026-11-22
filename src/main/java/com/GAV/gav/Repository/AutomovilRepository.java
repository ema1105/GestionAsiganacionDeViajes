package com.GAV.gav.Repository;

import com.GAV.gav.Model.Automovil;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AutomovilRepository extends JpaRepository<Automovil, Long> {

    Optional<Automovil> findByPlaca(String placa);

    List<Automovil> findByCategoriaNombre(String nombreCategoria);

    boolean existsByPlaca(String placa);

    // Devuelve true si el automóvil está actualmente asignado a algún Conductor.
    @Query("""
        SELECT COUNT(c) > 0 FROM Conductor c
        WHERE c.automovil.id = :automovilId
    """)
    boolean estaAsignadoAConductor(@Param("automovilId") Long automovilId);

    // Devuelve true si el automóvil aparece en algún Viaje (cualquier estado).
    @Query("""
        SELECT COUNT(v) > 0 FROM Viaje v
        WHERE v.automovil.id = :automovilId
    """)
    boolean tieneViajes(@Param("automovilId") Long automovilId);
}

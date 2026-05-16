package com.GAV.gav.Repository;

import com.GAV.gav.Model.Lugar;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface LugarRepository extends JpaRepository<Lugar, Long> {

    // Lugares activos (NULL se considera activo, por compatibilidad con datos previos).
    @Query("""
        SELECT l FROM Lugar l
        WHERE l.activo IS NULL OR l.activo = true
        ORDER BY l.nombre ASC
    """)
    List<Lugar> findActivos();
}

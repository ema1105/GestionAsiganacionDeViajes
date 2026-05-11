package com.GAV.gav.Repository;

import com.GAV.gav.Model.SeguimientoViaje;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SeguimientoViajeRepository extends JpaRepository<SeguimientoViaje, Long> {

    // Recorrido completo del viaje en orden cronológico.
    List<SeguimientoViaje> findByViajeIdOrderByFechaAsc(Long viajeId);

    // Último punto registrado para un viaje (útil para vista real-time del cliente).
    Optional<SeguimientoViaje> findTopByViajeIdOrderByFechaDesc(Long viajeId);
}

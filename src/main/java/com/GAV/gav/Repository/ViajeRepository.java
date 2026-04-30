package com.GAV.gav.Repository;

import com.GAV.gav.Model.Viaje;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface ViajeRepository extends JpaRepository<Viaje, Long> {
    List<Viaje> findByClienteId(Long clienteId);

    List<Viaje> findByConductorId(Long conductorId);

    List<Viaje> findByEstadoViaje(Viaje.EstadoViaje estado);

    /*
    * Trae viajes que aun no tienen conductor
    * viaje en proceso de asignacion
    * MÁS DIRECTO
    * */
    @Query("""
        SELECT v FROM Viaje v
        WHERE v.estadoViaje IN ('SOLICITADO', 'BUSCANDO_CONDUCTOR')
    """)
    List<Viaje> findViajesPendientes();

    /*
    Paginacion para evitar sobre-carga o traida de muchos datos
    */
    Page<Viaje> findByClienteId(Long clienteId, Pageable pageable);
}

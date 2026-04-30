package com.GAV.gav.Repository;

import com.GAV.gav.Model.CategoriaVehiculo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface CategoriaVehiculoRepository extends JpaRepository<CategoriaVehiculo, Long> {

    Optional<CategoriaVehiculo>findByNombre(String nombre);


}

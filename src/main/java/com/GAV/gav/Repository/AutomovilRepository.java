package com.GAV.gav.Repository;

import com.GAV.gav.Model.Automovil;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AutomovilRepository extends JpaRepository<Automovil, Long> {

    Optional<Automovil> findByPlaca(String placa);

    List<Automovil>findByCategoriaNombre(String nombreCategoria);

}

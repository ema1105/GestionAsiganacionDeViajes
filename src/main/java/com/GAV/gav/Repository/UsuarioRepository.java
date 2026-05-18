package com.GAV.gav.Repository;

import com.GAV.gav.Model.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    Optional<Usuario> findByNombreUsuario(String nombreUsuario);

    // Usuarios por nombre de rol (ej. "ROLE_CLIENTE") para el listado admin.
    List<Usuario> findByRol_Nombre(String nombreRol);

    Optional<Usuario> findByEmail(String email);

    Optional<Usuario> findByTelefono(String telefono);

    // CORRECCIÓN: el nombre correcto en Spring Data es "existsBy" (con 's'), no "existBy"
    // Los métodos anteriores causaban error de arranque por nombre de método inválido
    boolean existsByEmail(String email);

    boolean existsByNumeroDocumento(String numeroDocumento);

    boolean existsByTelefono(String telefono);

    boolean existsByNombreUsuario(String nombreUsuario);
}

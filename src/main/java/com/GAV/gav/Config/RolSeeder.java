package com.GAV.gav.Config;

import com.GAV.gav.Model.Rol;
import com.GAV.gav.Repository.RolRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;

// Garantiza que los roles base del sistema existan al iniciar la aplicación.
// Idempotente: solo inserta el rol que falte, nunca duplica.
// Resuelve de raíz el error "Rol ROLE_CLIENTE no encontrado" en entornos
// nuevos, despliegues limpios o tras un ddl-auto=create.
//
// Los nombres llevan el prefijo ROLE_ porque así los consulta AuthService
// (findByNombre("ROLE_CLIENTE")) y los espera Spring Security.
@Component
@Order(0) // antes que LugarSeeder (@Order(1)) y cualquier otro runner
@RequiredArgsConstructor
public class RolSeeder implements CommandLineRunner {

    private final RolRepository rolRepository;

    private static final List<String> ROLES_BASE = List.of(
            "ROLE_ADMIN",
            "ROLE_CLIENTE",
            "ROLE_CONDUCTOR",
            "ROLE_RECEPCIONISTA"
    );

    @Override
    public void run(String... args) {
        for (String nombre : ROLES_BASE) {
            if (rolRepository.findByNombre(nombre).isEmpty()) {
                Rol rol = new Rol();
                rol.setNombre(nombre);
                rolRepository.save(rol);
            }
        }
    }
}

package com.GAV.gav.Config;

import com.GAV.gav.Model.Rol;
import com.GAV.gav.Repository.RolRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;

// Siembra los roles base del sistema al arrancar si aún no existen.
// Debe ejecutarse ANTES que cualquier otro seeder (@Order(0)).
// Es completamente idempotente: si el rol ya existe, no lo toca.
@Slf4j
@Component
@Order(0)
@RequiredArgsConstructor
public class RolSeeder implements CommandLineRunner {

    private final RolRepository rolRepository;

    private static final List<String> ROLES = List.of(
        "ROLE_ADMIN",
        "ROLE_CLIENTE",
        "ROLE_CONDUCTOR",
        "ROLE_RECEPCIONISTA"
    );

    @Override
    public void run(String... args) {
        int creados = 0;
        for (String nombre : ROLES) {
            if (rolRepository.findByNombre(nombre).isEmpty()) {
                Rol rol = new Rol();
                rol.setNombre(nombre);
                rolRepository.save(rol);
                creados++;
                log.info("[RolSeeder] Rol creado: {}", nombre);
            }
        }
        if (creados == 0) {
            log.info("[RolSeeder] Todos los roles ya existen, nada que insertar.");
        } else {
            log.info("[RolSeeder] {} rol(es) creados exitosamente.", creados);
        }
    }
}

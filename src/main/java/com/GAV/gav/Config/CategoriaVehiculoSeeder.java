package com.GAV.gav.Config;

import com.GAV.gav.Model.CategoriaVehiculo;
import com.GAV.gav.Repository.CategoriaVehiculoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

// Siembra las categorías de vehículo base si no existen.
// Sin categorías, el registro de conductor+vehículo falla (categoriaVehiculoId
// inválido). Los nombres coinciden con los tipos que muestra el frontend
// (CONFORT, PREMIUM, XL). Idempotente: no duplica categorías existentes.
// Corre después de RolSeeder/TarifaSeeder/AdminSeeder (@Order(3)).
@Slf4j
@Component
@Order(3)
@RequiredArgsConstructor
public class CategoriaVehiculoSeeder implements CommandLineRunner {

    private final CategoriaVehiculoRepository categoriaVehiculoRepository;

    private static final List<Map<String, String>> CATEGORIAS = List.of(
            Map.of("nombre", "CONFORT",
                   "descripcion", "Vehículo estándar cómodo para trayectos urbanos"),
            Map.of("nombre", "PREMIUM",
                   "descripcion", "Vehículo de gama alta con mayor confort"),
            Map.of("nombre", "XL",
                   "descripcion", "Vehículo amplio para grupos de 5 o más pasajeros")
    );

    @Override
    public void run(String... args) {
        int creadas = 0;
        for (Map<String, String> c : CATEGORIAS) {
            if (categoriaVehiculoRepository.findByNombre(c.get("nombre")).isEmpty()) {
                CategoriaVehiculo cat = new CategoriaVehiculo();
                cat.setNombre(c.get("nombre"));
                cat.setDescripcion(c.get("descripcion"));
                categoriaVehiculoRepository.save(cat);
                creadas++;
                log.info("[CategoriaVehiculoSeeder] Categoría creada: {}", c.get("nombre"));
            }
        }
        if (creadas == 0) {
            log.info("[CategoriaVehiculoSeeder] Todas las categorías ya existen.");
        } else {
            log.info("[CategoriaVehiculoSeeder] {} categoría(s) creadas.", creadas);
        }
    }
}

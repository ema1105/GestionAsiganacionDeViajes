package com.GAV.gav.Config;

import com.GAV.gav.Model.Tarifa;
import com.GAV.gav.Repository.TarifaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.math.BigDecimal;

// Siembra una tarifa activa por defecto si la tabla está vacía.
// Sin una tarifa activa, ViajeService.calcularPrecio() falla con
// "No hay una tarifa activa configurada" y el cliente no puede solicitar viajes.
// Idempotente: si ya existe una tarifa activa vigente, no inserta nada.
// Valores en COP, coherentes con la estimación del frontend (4000 + 2200/km).
@Slf4j
@Component
@Order(1)
@RequiredArgsConstructor
public class TarifaSeeder implements CommandLineRunner {

    private final TarifaRepository tarifaRepository;

    @Override
    public void run(String... args) {
        if (tarifaRepository.findByTarifaActiva().isPresent()) {
            log.info("[TarifaSeeder] Ya existe una tarifa activa, nada que insertar.");
            return;
        }

        Tarifa tarifa = new Tarifa();
        tarifa.setPrecioBase(new BigDecimal("4000"));
        tarifa.setPrecioPorKm(new BigDecimal("2200"));
        tarifa.setPrecioPorMinuto(new BigDecimal("200"));
        tarifa.setMultiplicadorDinamico(BigDecimal.ONE);
        // Sin fechaInicio/fechaFin: la tarifa se considera siempre vigente.
        tarifa.setFechaInicio(null);
        tarifa.setFechaFin(null);
        tarifa.setActivo(true);

        tarifaRepository.save(tarifa);
        log.info("[TarifaSeeder] Tarifa activa por defecto creada: base={} porKm={} porMin={}",
                tarifa.getPrecioBase(), tarifa.getPrecioPorKm(), tarifa.getPrecioPorMinuto());
    }
}

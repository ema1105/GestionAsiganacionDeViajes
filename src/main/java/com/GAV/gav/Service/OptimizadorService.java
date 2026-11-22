package com.GAV.gav.Service;

import com.GAV.gav.DTO.Response.AsignacionResultDTO;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.Viaje;
import com.GAV.gav.Repository.ConductorRepository;
import com.GAV.gav.Repository.ViajeRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.restclient.RestTemplateBuilder;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;
import java.util.Map;

// Cliente del microservicio Python de optimización (ILP).
// 1) Valida que haya datos suficientes ANTES de llamar (evita 503/500 inútiles).
// 2) Hace POST a /api/v1/assign y valida la respuesta antes de devolverla.
// 3) Loguea cada fase para diagnóstico real (no oculta el error).
@Slf4j
@Service
@RequiredArgsConstructor
public class OptimizadorService {

    private final RestTemplateBuilder restTemplateBuilder;
    private final ViajeRepository viajeRepository;
    private final ConductorRepository conductorRepository;

    @Value("${optimizador.url:http://localhost:8001/api/v1/assign}")
    private String optimizadorUrl;

    @Value("${optimizador.timeout-ms:15000}")
    private long timeoutMs;

    // Mínimos para que tenga sentido ejecutar el modelo (configurables).
    @Value("${optimizador.min-viajes:1}")
    private int minViajes;

    @Value("${optimizador.min-conductores:1}")
    private int minConductores;

    public AsignacionResultDTO ejecutarOptimizacion() {
        // ── 1. Validación lógica previa: datos suficientes ──────────────────
        long viajesPendientes = viajeRepository
                .findByEstadoViaje(Viaje.EstadoViaje.BUSCANDO_CONDUCTOR).size();
        long conductoresDisponibles = conductorRepository
                .findByConductoresDisponibles().stream()
                .filter(c -> c.getActivo() == null || Boolean.TRUE.equals(c.getActivo()))
                .count();

        log.info("[Optimizador] Pre-validación: viajesPendientes={}, conductoresDisponibles={} "
                        + "(mínimos: viajes={}, conductores={})",
                viajesPendientes, conductoresDisponibles, minViajes, minConductores);

        if (viajesPendientes < minViajes || conductoresDisponibles < minConductores) {
            String msg = String.format(
                    "No hay datos suficientes para ejecutar la optimización. "
                            + "Se requieren al menos %d viaje(s) en BUSCANDO_CONDUCTOR y "
                            + "%d conductor(es) disponible(s). Actual: %d viaje(s), %d conductor(es).",
                    minViajes, minConductores, viajesPendientes, conductoresDisponibles);
            log.warn("[Optimizador] Abortado por datos insuficientes: {}", msg);
            // 422: petición válida pero no procesable por estado del sistema (no es 5xx).
            throw new BusinessException(msg, HttpStatus.UNPROCESSABLE_ENTITY);
        }

        // ── 2. Llamada al microservicio ─────────────────────────────────────
        RestTemplate restTemplate = restTemplateBuilder
                .connectTimeout(Duration.ofMillis(timeoutMs))
                .readTimeout(Duration.ofMillis(timeoutMs))
                .build();

        log.info("[Optimizador] Invocando microservicio: {}", optimizadorUrl);
        try {
            AsignacionResultDTO resultado = restTemplate.postForObject(
                    optimizadorUrl, Map.of(), AsignacionResultDTO.class);

            // ── 3. Validación de la respuesta antes de devolverla ───────────
            if (resultado == null) {
                log.error("[Optimizador] Respuesta nula del microservicio.");
                throw new BusinessException(
                        "El microservicio de optimización devolvió una respuesta vacía.",
                        HttpStatus.BAD_GATEWAY);
            }
            if (resultado.getAsignaciones() == null) {
                log.error("[Optimizador] Respuesta sin campo 'asignaciones': {}", resultado);
                throw new BusinessException(
                        "La respuesta del microservicio tiene un formato inválido "
                                + "(falta 'asignaciones').",
                        HttpStatus.BAD_GATEWAY);
            }
            log.info("[Optimizador] OK — status='{}', asignaciones={}, viajesCubiertos={}",
                    resultado.getStatus(),
                    resultado.getAsignaciones().size(),
                    resultado.getViajesCubiertos());
            return resultado;

        } catch (BusinessException be) {
            throw be;
        } catch (ResourceAccessException e) {
            // Conexión rechazada / timeout: el microservicio no está disponible.
            log.error("[Optimizador] Microservicio inaccesible en {} — {}",
                    optimizadorUrl, e.getMessage());
            throw new BusinessException(
                    "El microservicio de optimización no está disponible. "
                            + "Verifica que esté corriendo en " + optimizadorUrl
                            + " (uvicorn main:app --port 8001).",
                    HttpStatus.SERVICE_UNAVAILABLE);
        } catch (RestClientException e) {
            log.error("[Optimizador] Error HTTP del microservicio: {}", e.getMessage(), e);
            throw new BusinessException(
                    "Error consultando el microservicio de optimización: " + e.getMessage(),
                    HttpStatus.BAD_GATEWAY);
        }
    }
}

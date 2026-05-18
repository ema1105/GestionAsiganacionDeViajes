package com.GAV.gav.Service;

import com.GAV.gav.DTO.Response.AsignacionResultDTO;
import com.GAV.gav.Exception.BusinessException;
import lombok.RequiredArgsConstructor;
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
// Hace POST al endpoint /api/v1/assign y mapea la respuesta a AsignacionResultDTO.
// No modifica estado: solo dispara el cálculo y devuelve el resultado.
@Service
@RequiredArgsConstructor
public class OptimizadorService {

    private final RestTemplateBuilder restTemplateBuilder;

    // Configurable por properties; default = microservicio local en :8001.
    @Value("${optimizador.url:http://localhost:8001/api/v1/assign}")
    private String optimizadorUrl;

    @Value("${optimizador.timeout-ms:15000}")
    private long timeoutMs;

    public AsignacionResultDTO ejecutarOptimizacion() {
        RestTemplate restTemplate = restTemplateBuilder
                .connectTimeout(Duration.ofMillis(timeoutMs))
                .readTimeout(Duration.ofMillis(timeoutMs))
                .build();
        try {
            // Body vacío: el microservicio usa sus filtros por defecto.
            AsignacionResultDTO resultado = restTemplate.postForObject(
                    optimizadorUrl, Map.of(), AsignacionResultDTO.class);

            if (resultado == null) {
                throw new BusinessException(
                        "El microservicio de optimización devolvió una respuesta vacía.",
                        HttpStatus.BAD_GATEWAY);
            }
            return resultado;
        } catch (BusinessException be) {
            throw be;
        } catch (ResourceAccessException e) {
            // Conexión rechazada / timeout: el microservicio no está disponible.
            throw new BusinessException(
                    "El microservicio de optimización no está disponible "
                            + "(¿está corriendo en " + optimizadorUrl + "?).",
                    HttpStatus.SERVICE_UNAVAILABLE);
        } catch (RestClientException e) {
            throw new BusinessException(
                    "Error consultando el microservicio de optimización: " + e.getMessage(),
                    HttpStatus.BAD_GATEWAY);
        }
    }
}

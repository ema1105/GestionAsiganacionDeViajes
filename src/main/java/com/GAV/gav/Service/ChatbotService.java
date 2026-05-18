package com.GAV.gav.Service;

import com.GAV.gav.DTO.Response.ChatbotResponse;
import com.GAV.gav.DTO.Response.LugarPopularResponse;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.Lugar;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.time.Duration;
import java.util.List;
import java.util.Map;

// Chatbot SOLO de sugerencia de lugares para clientes.
// Alcance: lugares más solicitados (históricos) + sugerencias según lo que busque
// el cliente, limitado a Cartagena de Indias y corregimientos aledaños.
// NO responde sobre el uso del servicio/app (fuera de alcance).
// Sin estado: cada mensaje es independiente, no se persiste historial.
@Slf4j
@Service
@RequiredArgsConstructor
public class ChatbotService {

    private final LugarService lugarService;

    @Value("${chatbot.api-url:}")
    private String apiUrl;

    @Value("${chatbot.api-key:}")
    private String apiKey;

    @Value("${chatbot.timeout-ms:15000}")
    private long timeoutMs;

    @Value("${chatbot.max-lugares-grounding:25}")
    private int maxLugaresGrounding;

    @Value("${chatbot.top-solicitados:10}")
    private int topSolicitados;

    public ChatbotResponse responder(String mensajeUsuario) {
        // Degradación elegante: si no hay clave configurada, devolvemos una respuesta
        // amigable en lugar de error técnico. La app sigue funcionando sin el chatbot.
        if (apiKey == null || apiKey.isBlank()) {
            return ChatbotResponse.builder()
                    .respuesta("El asistente no está disponible en este momento. " +
                               "Consulta los puntos de referencia de la app para elegir tu destino en Cartagena.")
                    .lugaresMasSolicitados(lugarService.lugaresMasSolicitados(topSolicitados))
                    .build();
        }
        if (apiUrl == null || apiUrl.isBlank()) {
            return ChatbotResponse.builder()
                    .respuesta("El asistente no está configurado correctamente. " +
                               "Contacta al administrador.")
                    .lugaresMasSolicitados(lugarService.lugaresMasSolicitados(topSolicitados))
                    .build();
        }

        List<LugarPopularResponse> populares = lugarService.lugaresMasSolicitados(topSolicitados);
        String systemPrompt = construirSystemPrompt(populares);

        String texto = llamarGemini(systemPrompt, mensajeUsuario);

        return ChatbotResponse.builder()
                .respuesta(texto)
                .lugaresMasSolicitados(populares)
                .build();
    }

    private String construirSystemPrompt(List<LugarPopularResponse> populares) {
        StringBuilder sb = new StringBuilder();
        sb.append("Eres un asistente que SOLO sugiere lugares y destinos en ")
          .append("Cartagena de Indias (Colombia) y sus corregimientos aledaños. ")
          .append("Reglas estrictas:\n")
          .append("- NO respondas sobre el uso de la app, tarifas, soporte ni cómo solicitar viajes. ")
          .append("Si te preguntan eso, redirige amablemente a sugerir un destino.\n")
          .append("- Si preguntan por otra ciudad o país, aclara cortésmente que solo cubres Cartagena y aledaños.\n")
          .append("- Sé breve, concreto y útil. Recomienda lugares reales de la lista de catálogo cuando apliquen.\n\n");

        if (!populares.isEmpty()) {
            sb.append("LUGARES MÁS SOLICITADOS (según históricos de la app):\n");
            for (LugarPopularResponse l : populares) {
                sb.append("- ").append(l.getNombre())
                  .append(" (").append(l.getCategoria()).append(", ")
                  .append(l.getTotalViajes()).append(" viajes)\n");
            }
            sb.append("\n");
        }

        List<Lugar> catalogo = lugarService.catalogoActivo();
        if (!catalogo.isEmpty()) {
            sb.append("CATÁLOGO DE LUGARES CONOCIDOS (úsalos para emparejar con lo que pida el cliente):\n");
            catalogo.stream().limit(Math.max(1, maxLugaresGrounding)).forEach(l ->
                sb.append("- ").append(l.getNombre())
                  .append(" | ").append(l.getCategoria())
                  .append(" | ").append(l.getDescripcion() != null ? l.getDescripcion() : "")
                  .append(" | etiquetas: ").append(l.getEtiquetas() != null ? l.getEtiquetas() : "")
                  .append("\n"));
        }
        return sb.toString();
    }

    // Llama a la API de Gemini (generateContent). El formato es configurable por
    // properties; el proveedor por defecto es Gemini de Google AI Studio.
    @SuppressWarnings("unchecked")
    private String llamarGemini(String systemPrompt, String mensajeUsuario) {
        RestClient client = RestClient.builder()
                .requestFactory(timeoutRequestFactory())
                .build();

        Map<String, Object> body = Map.of(
                "systemInstruction", Map.of(
                        "parts", List.of(Map.of("text", systemPrompt))
                ),
                "contents", List.of(Map.of(
                        "role", "user",
                        "parts", List.of(Map.of("text", mensajeUsuario))
                ))
        );

        try {
            Map<String, Object> resp = client.post()
                    .uri(apiUrl + "?key=" + apiKey)
                    .header("Content-Type", "application/json")
                    .body(body)
                    .retrieve()
                    .body(Map.class);

            if (resp == null) {
                throw new BusinessException("El chatbot no devolvió respuesta.",
                        HttpStatus.BAD_GATEWAY);
            }

            List<Map<String, Object>> candidates =
                    (List<Map<String, Object>>) resp.get("candidates");
            if (candidates == null || candidates.isEmpty()) {
                throw new BusinessException(
                        "El chatbot no pudo generar una sugerencia.",
                        HttpStatus.BAD_GATEWAY);
            }
            Map<String, Object> content =
                    (Map<String, Object>) candidates.get(0).get("content");
            List<Map<String, Object>> parts =
                    (List<Map<String, Object>>) content.get("parts");
            Object text = parts.get(0).get("text");
            return text != null ? text.toString().trim() : "";
        } catch (BusinessException be) {
            throw be;
        } catch (RestClientResponseException httpEx) {
            // Error HTTP de Gemini con código y cuerpo: clave para diagnóstico real.
            // Causas típicas: 404 (modelo retirado/ruta incorrecta), 403 (API key
            // inválida o restringida), 429 (cuota/límite excedido).
            int code = httpEx.getStatusCode().value();
            log.error("Gemini respondió HTTP {} — {}. Cuerpo: {}",
                    code, httpEx.getStatusText(),
                    httpEx.getResponseBodyAsString());
            return switch (code) {
                case 404 -> "El asistente está temporalmente fuera de servicio " +
                        "(modelo no disponible). El equipo ya fue notificado.";
                case 403 -> "El asistente no está disponible por un problema de " +
                        "credenciales. Contacta al administrador.";
                case 429 -> "El asistente está recibiendo muchas solicitudes. " +
                        "Intenta de nuevo en unos minutos.";
                default -> "Lo siento, no pude conectar con el asistente ahora. " +
                        "Prueba de nuevo en unos momentos o consulta los lugares populares.";
            };
        } catch (Exception e) {
            // Fallo de red/timeout/parseo. Se registra para diagnóstico; el
            // cliente recibe un mensaje amable sin detalles técnicos.
            log.error("Fallo al invocar el chatbot Gemini: {}", e.toString(), e);
            return "Lo siento, no pude conectar con el asistente ahora. " +
                   "Prueba de nuevo en unos momentos o consulta los lugares populares de la app.";
        }
    }

    private org.springframework.http.client.ClientHttpRequestFactory timeoutRequestFactory() {
        org.springframework.http.client.SimpleClientHttpRequestFactory f =
                new org.springframework.http.client.SimpleClientHttpRequestFactory();
        f.setConnectTimeout(Duration.ofMillis(timeoutMs));
        f.setReadTimeout(Duration.ofMillis(timeoutMs));
        return f;
    }
}

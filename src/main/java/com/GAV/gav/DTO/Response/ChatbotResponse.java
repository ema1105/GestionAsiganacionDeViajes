package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

// Respuesta del chatbot: texto sugerido por el LLM + (opcional) lugares más
// solicitados que se usaron como contexto para que el front los muestre.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class ChatbotResponse {

    private String respuesta;
    private List<LugarPopularResponse> lugaresMasSolicitados;
}

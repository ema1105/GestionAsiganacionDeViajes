package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Request.ChatbotRequest;
import com.GAV.gav.DTO.Response.ChatbotResponse;
import com.GAV.gav.Security.AuthenticatedUserProvider;
import com.GAV.gav.Service.ChatbotService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

// Chatbot de sugerencia de lugares para clientes.
// Queda cubierto por el matcher /api/cliente/** (ROLE_CLIENTE) en SecurityConfig.
@RestController
@RequestMapping("/api/cliente/chatbot")
@RequiredArgsConstructor
public class ChatbotController {

    private final ChatbotService chatbotService;
    private final AuthenticatedUserProvider authenticatedUserProvider;

    @PostMapping("/mensaje")
    public ResponseEntity<ChatbotResponse> mensaje(
            @Valid @RequestBody ChatbotRequest request) {
        // getCurrentUserId valida que haya un cliente autenticado válido.
        authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(chatbotService.responder(request.getMensaje()));
    }
}

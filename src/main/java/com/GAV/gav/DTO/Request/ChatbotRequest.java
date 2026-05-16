package com.GAV.gav.DTO.Request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

// Mensaje del cliente al chatbot de sugerencia de lugares.
@Data
public class ChatbotRequest {

    @NotBlank(message = "El mensaje es obligatorio")
    @Size(max = 1000, message = "El mensaje no puede superar 1000 caracteres")
    private String mensaje;
}

package com.GAV.gav.Exception;

import org.springframework.http.HttpStatus;

// Excepción de dominio para errores de negocio esperados (validaciones, recursos no encontrados, etc.)
// Evita que los services lancen excepciones genéricas sin contexto HTTP
public class BusinessException extends RuntimeException {

    private final HttpStatus status;

    public BusinessException(String message, HttpStatus status) {
        super(message);
        this.status = status;
    }

    public HttpStatus getStatus() {
        return status;
    }
}

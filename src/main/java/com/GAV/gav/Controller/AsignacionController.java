package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Response.AsignacionResultDTO;
import com.GAV.gav.Service.OptimizadorService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

// Dispara la optimización ILP llamando al microservicio Python.
// Queda cubierto por el matcher por defecto de SecurityConfig (.anyRequest().authenticated()),
// por lo que requiere un usuario autenticado.
@RestController
@RequestMapping("/api/asignacion")
@RequiredArgsConstructor
public class AsignacionController {

    private final OptimizadorService optimizadorService;

    @PostMapping("/ejecutar")
    public ResponseEntity<AsignacionResultDTO> ejecutar() {
        return ResponseEntity.ok(optimizadorService.ejecutarOptimizacion());
    }
}

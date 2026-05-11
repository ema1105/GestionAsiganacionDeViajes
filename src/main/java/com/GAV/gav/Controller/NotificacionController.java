package com.GAV.gav.Controller;

import com.GAV.gav.DTO.Response.NotificacionResponse;
import com.GAV.gav.Security.AuthenticatedUserProvider;
import com.GAV.gav.Service.NotificacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

// Endpoints de notificaciones para cualquier usuario autenticado.
// El frontend hace polling a /no-leidas cada N segundos.
@RestController
@RequestMapping("/api/notificaciones")
@RequiredArgsConstructor
public class NotificacionController {

    private final NotificacionService notificacionService;
    private final AuthenticatedUserProvider authenticatedUserProvider;

    @GetMapping("/mias")
    public ResponseEntity<List<NotificacionResponse>> listarMias() {
        Long usuarioId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(notificacionService.listarTodas(usuarioId));
    }

    @GetMapping("/no-leidas")
    public ResponseEntity<List<NotificacionResponse>> listarNoLeidas() {
        Long usuarioId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(notificacionService.listarNoLeidas(usuarioId));
    }

    @GetMapping("/no-leidas/count")
    public ResponseEntity<Map<String, Long>> contarNoLeidas() {
        Long usuarioId = authenticatedUserProvider.getCurrentUserId();
        long count = notificacionService.contarNoLeidas(usuarioId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    @PutMapping("/{id}/leer")
    public ResponseEntity<NotificacionResponse> marcarComoLeida(@PathVariable Long id) {
        Long usuarioId = authenticatedUserProvider.getCurrentUserId();
        return ResponseEntity.ok(notificacionService.marcarComoLeida(id, usuarioId));
    }
}

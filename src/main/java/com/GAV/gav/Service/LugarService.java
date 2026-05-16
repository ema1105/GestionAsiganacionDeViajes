package com.GAV.gav.Service;

import com.GAV.gav.DTO.Response.LugarPopularResponse;
import com.GAV.gav.Model.Lugar;
import com.GAV.gav.Repository.LugarRepository;
import com.GAV.gav.Repository.ViajeRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;

// Consultas de lugares: ranking de "más solicitados" según históricos de viajes
// y catálogo activo (usado para grounding del chatbot).
@Service
@RequiredArgsConstructor
public class LugarService {

    private final ViajeRepository viajeRepository;
    private final LugarRepository lugarRepository;

    public List<LugarPopularResponse> lugaresMasSolicitados(int limite) {
        int lim = limite <= 0 ? 10 : Math.min(limite, 50);
        return viajeRepository.lugaresMasSolicitados(PageRequest.of(0, lim))
                .stream()
                .map(row -> {
                    Lugar l = (Lugar) row[0];
                    long total = ((Number) row[1]).longValue();
                    return LugarPopularResponse.builder()
                            .id(l.getId())
                            .nombre(l.getNombre())
                            .categoria(l.getCategoria())
                            .descripcion(l.getDescripcion())
                            .totalViajes(total)
                            .build();
                })
                .toList();
    }

    public List<Lugar> catalogoActivo() {
        return lugarRepository.findActivos();
    }
}

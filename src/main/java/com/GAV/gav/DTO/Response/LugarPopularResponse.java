package com.GAV.gav.DTO.Response;

import com.GAV.gav.Model.Lugar;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

// Lugar dentro del ranking de "más solicitados" según históricos de viajes.
@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class LugarPopularResponse {

    private Long id;
    private String nombre;
    private Lugar.Categoria categoria;
    private String descripcion;
    private long totalViajes;
}

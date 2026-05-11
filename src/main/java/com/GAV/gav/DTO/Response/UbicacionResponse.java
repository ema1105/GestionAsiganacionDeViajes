package com.GAV.gav.DTO.Response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class UbicacionResponse {

    private Long id;
    private Long conductorId;
    private BigDecimal lat;
    private BigDecimal lng;
    private LocalDateTime fecha;
}

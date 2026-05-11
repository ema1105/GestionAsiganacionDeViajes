package com.GAV.gav.Model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Puntos GPS registrados durante un viaje activo. Permite reconstruir la ruta
// y mostrar al cliente la posición del conductor en tiempo real durante el trayecto.
@Entity
@Table(name = "seguimiento_viaje")
public class SeguimientoViaje {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "viaje_id")
    private Viaje viaje;

    @Column(name = "lat")
    private BigDecimal lat;

    @Column(name = "lng")
    private BigDecimal lng;

    @Column(name = "fecha")
    private LocalDateTime fecha;

    public SeguimientoViaje() {}

    public SeguimientoViaje(Long id, Viaje viaje, BigDecimal lat,
                            BigDecimal lng, LocalDateTime fecha) {
        this.id = id;
        this.viaje = viaje;
        this.lat = lat;
        this.lng = lng;
        this.fecha = fecha;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Viaje getViaje() { return viaje; }
    public void setViaje(Viaje viaje) { this.viaje = viaje; }

    public BigDecimal getLat() { return lat; }
    public void setLat(BigDecimal lat) { this.lat = lat; }

    public BigDecimal getLng() { return lng; }
    public void setLng(BigDecimal lng) { this.lng = lng; }

    public LocalDateTime getFecha() { return fecha; }
    public void setFecha(LocalDateTime fecha) { this.fecha = fecha; }
}

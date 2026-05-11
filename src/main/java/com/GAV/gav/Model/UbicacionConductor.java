package com.GAV.gav.Model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Historial de posiciones GPS de un conductor. Se inserta una fila por cada
// heartbeat de ubicación que envía el conductor (independiente de si tiene viaje).
// Sirve para mostrar al cliente "conductores cercanos" antes de solicitar un viaje.
@Entity
@Table(name = "ubicacion_conductor")
public class UbicacionConductor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "conductor_id")
    private Conductor conductor;

    @Column(name = "lat")
    private BigDecimal lat;

    @Column(name = "lng")
    private BigDecimal lng;

    @Column(name = "fecha")
    private LocalDateTime fecha;

    public UbicacionConductor() {}

    public UbicacionConductor(Long id, Conductor conductor, BigDecimal lat,
                              BigDecimal lng, LocalDateTime fecha) {
        this.id = id;
        this.conductor = conductor;
        this.lat = lat;
        this.lng = lng;
        this.fecha = fecha;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Conductor getConductor() { return conductor; }
    public void setConductor(Conductor conductor) { this.conductor = conductor; }

    public BigDecimal getLat() { return lat; }
    public void setLat(BigDecimal lat) { this.lat = lat; }

    public BigDecimal getLng() { return lng; }
    public void setLng(BigDecimal lng) { this.lng = lng; }

    public LocalDateTime getFecha() { return fecha; }
    public void setFecha(LocalDateTime fecha) { this.fecha = fecha; }
}

package com.GAV.gav.Model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

// CORRECCIÓN: el nombre de tabla original era "vaije_conductor" (typo). Corregido a "viaje_conductor".
// Si la tabla ya existe en BD hay que aplicar una migración de renombrado.
@Entity
@Table(name = "viaje_conductor")
public class ViajeConductor {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // CAMBIO: se agrega @JoinColumn explícito en ambas relaciones para claridad
    @ManyToOne
    @JoinColumn(name = "viaje_id")
    private Viaje viaje;

    @ManyToOne
    @JoinColumn(name = "conductor_id")
    private Conductor conductor;

    public enum EstadoSolicitud {
        PENDIENTE, ACEPTADO, RECHAZADO, EXPIRADO
    }

    @Enumerated(EnumType.STRING)
    private EstadoSolicitud estado;

    @Column(name = "fechaOferta")
    private LocalDateTime fechaOferta;

    @Column(name = "fechaRespuesta")
    private LocalDateTime fechaRespuesta;

    // NUEVO: límite de tiempo para que el conductor responda la solicitud.
    // Si el momento actual supera este valor y el estado sigue en PENDIENTE,
    // el scheduler en ViajeService lo marca EXPIRADO y avanza al siguiente en la cola FIFO.
    @Column(name = "fechaExpiracion")
    private LocalDateTime fechaExpiracion;

    public ViajeConductor() {}

    // Constructor para crear una nueva oferta al vuelo
    public ViajeConductor(Viaje viaje, Conductor conductor, EstadoSolicitud estado,
                          LocalDateTime fechaOferta, LocalDateTime fechaExpiracion) {
        this.viaje = viaje;
        this.conductor = conductor;
        this.estado = estado;
        this.fechaOferta = fechaOferta;
        this.fechaExpiracion = fechaExpiracion;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Viaje getViaje() { return viaje; }
    public void setViaje(Viaje viaje) { this.viaje = viaje; }

    public Conductor getConductor() { return conductor; }
    public void setConductor(Conductor conductor) { this.conductor = conductor; }

    public EstadoSolicitud getEstado() { return estado; }
    public void setEstado(EstadoSolicitud estado) { this.estado = estado; }

    public LocalDateTime getFechaOferta() { return fechaOferta; }
    public void setFechaOferta(LocalDateTime fechaOferta) { this.fechaOferta = fechaOferta; }

    public LocalDateTime getFechaRespuesta() { return fechaRespuesta; }
    public void setFechaRespuesta(LocalDateTime fechaRespuesta) { this.fechaRespuesta = fechaRespuesta; }

    public LocalDateTime getFechaExpiracion() { return fechaExpiracion; }
    public void setFechaExpiracion(LocalDateTime fechaExpiracion) { this.fechaExpiracion = fechaExpiracion; }

    @Override
    public String toString() {
        return "ViajeConductor{" +
                "id=" + id +
                ", viaje=" + (viaje != null ? viaje.getId() : null) +
                ", conductor=" + (conductor != null ? conductor.getUsuarioId() : null) +
                ", estado=" + estado +
                ", fechaOferta=" + fechaOferta +
                ", fechaExpiracion=" + fechaExpiracion +
                '}';
    }
}

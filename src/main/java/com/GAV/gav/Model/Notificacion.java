package com.GAV.gav.Model;


import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "notificacion")
public class Notificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @ManyToOne
    @JoinColumn(name = "viaje_id")
    private Viaje viaje;

    // NUEVOS: VIAJE_ACEPTADO, VIAJE_EN_CURSO, VIAJE_CANCELADO para cubrir todo el ciclo de estados.
    public enum TipoNotificacion {
        // Notificación al CONDUCTOR cuando el FIFO le asigna una solicitud pendiente
        NUEVA_SOLICITUD,
        // Notificaciones al CLIENTE en cada cambio de estado del viaje
        CONDUCTOR_ASIGNADO,
        CONDUCTOR_EN_CAMINO,
        VIAJE_ACEPTADO,
        VIAJE_INICIADO,
        VIAJE_EN_CURSO,
        VIAJE_FINALIZADO,
        VIAJE_CANCELADO,
        // Notificación bidireccional cuando un usuario recibe una nueva calificación
        NUEVA_CALIFICACION
    }

    @Enumerated(EnumType.STRING)
    private TipoNotificacion tipoNotificacion;

    @Column(name = "mensaje")
    private String mensaje;

    @Column(name = "leida")
    private Boolean leida;

    @Column(name = "fechaCreacion")
    private LocalDateTime fechaCreacion;

    public Notificacion() {
    }

    public Notificacion(Long id, Usuario usuario, Viaje viaje, TipoNotificacion tipoNotificacion,
                        String mensaje, Boolean leida, LocalDateTime fechaCreacion) {
        this.id = id;
        this.usuario = usuario;
        this.viaje = viaje;
        this.tipoNotificacion = tipoNotificacion;
        this.mensaje = mensaje;
        this.leida = leida;
        this.fechaCreacion = fechaCreacion;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Usuario getUsuario() {
        return usuario;
    }

    public void setUsuario(Usuario usuario) {
        this.usuario = usuario;
    }

    public Viaje getViaje() {
        return viaje;
    }

    public void setViaje(Viaje viaje) {
        this.viaje = viaje;
    }

    public TipoNotificacion getTipoNotificacion() {
        return tipoNotificacion;
    }

    public void setTipoNotificacion(TipoNotificacion tipoNotificacion) {
        this.tipoNotificacion = tipoNotificacion;
    }

    public String getMensaje() {
        return mensaje;
    }

    public void setMensaje(String mensaje) {
        this.mensaje = mensaje;
    }

    public Boolean getLeida() {
        return leida;
    }

    public void setLeida(Boolean leida) {
        this.leida = leida;
    }

    public LocalDateTime getFechaCreacion() {
        return fechaCreacion;
    }

    public void setFechaCreacion(LocalDateTime fechaCreacion) {
        this.fechaCreacion = fechaCreacion;
    }


    @Override
    public String toString() {
        return "Notificacion{" +
                "id=" + id +
                ", usuario=" + usuario +
                ", viaje=" + viaje +
                ", tipoNotificacion=" + tipoNotificacion +
                ", mensaje='" + mensaje + '\'' +
                ", leida=" + leida +
                ", fechaCreacion=" + fechaCreacion +
                '}';
    }
}

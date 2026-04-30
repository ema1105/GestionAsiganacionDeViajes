package com.GAV.gav.Model;


import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "notificacion")
public class Notificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long Id;

    @ManyToOne
    private Usuario usuario;

    @ManyToOne
    private Viaje viaje;

    @Enumerated(EnumType.STRING)
    private TipoNotificacion tipoNotificacion;

    private enum TipoNotificacion{
        CONDUTOR_ASIGNADO, VIAJE_INICIADO,
        VIAJE_FINALIZADO, CONDUCTOR_EN_CAMINO
    }

    @Column(name = "mensaje")
    private String mensaje;

    @Column(name = "leida")
    private Boolean leida;

    @Column(name = "fechaCreacion")
    private LocalDateTime fechaCreacion;

    public Notificacion() {
    }

    public Notificacion(Long id, Usuario usuario, Viaje viaje, TipoNotificacion tipoNotificacion, String mensaje, Boolean leida, LocalDateTime fechaCreaacion) {
        Id = id;
        this.usuario = usuario;
        this.viaje = viaje;
        this.tipoNotificacion = tipoNotificacion;
        this.mensaje = mensaje;
        this.leida = leida;
        this.fechaCreacion = fechaCreaacion;
    }

    public Long getId() {
        return Id;
    }

    public void setId(Long id) {
        Id = id;
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
                "Id=" + Id +
                ", usuario=" + usuario +
                ", viaje=" + viaje +
                ", tipoNotificacion=" + tipoNotificacion +
                ", mensaje='" + mensaje + '\'' +
                ", leida=" + leida +
                ", fechaCreacion=" + fechaCreacion +
                '}';
    }
}

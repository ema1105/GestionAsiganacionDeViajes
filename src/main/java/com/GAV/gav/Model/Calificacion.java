package com.GAV.gav.Model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

// Calificación bidireccional cliente↔conductor.
// El tipoCalificacion discrimina la dirección (CLIENTE_A_CONDUCTOR o CONDUCTOR_A_CLIENTE).
// Solo se permite una calificación por (viaje, calificador, tipo).
@Entity
@Table(name = "calificacion")
public class Calificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "viaje_id")
    private Viaje viaje;

    @ManyToOne
    @JoinColumn(name = "calificador_id")
    private Usuario calificador;

    @ManyToOne
    @JoinColumn(name = "calificado_id")
    private Usuario calificado;

    public enum TipoCalificacion {
        CLIENTE_A_CONDUCTOR,
        CONDUCTOR_A_CLIENTE
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "tipoCalificacion")
    private TipoCalificacion tipoCalificacion;

    @Column(name = "puntuacion")
    private Integer puntuacion;

    @Column(name = "comentario")
    private String comentario;

    @Column(name = "fechaCalificacion")
    private LocalDateTime fechaCalificacion;

    public Calificacion() {
    }

    public Calificacion(Long id, Viaje viaje, Usuario calificador, Usuario calificado,
                        TipoCalificacion tipoCalificacion, Integer puntuacion,
                        String comentario, LocalDateTime fechaCalificacion) {
        this.id = id;
        this.viaje = viaje;
        this.calificador = calificador;
        this.calificado = calificado;
        this.tipoCalificacion = tipoCalificacion;
        this.puntuacion = puntuacion;
        this.comentario = comentario;
        this.fechaCalificacion = fechaCalificacion;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Viaje getViaje() { return viaje; }
    public void setViaje(Viaje viaje) { this.viaje = viaje; }

    public Usuario getCalificador() { return calificador; }
    public void setCalificador(Usuario calificador) { this.calificador = calificador; }

    public Usuario getCalificado() { return calificado; }
    public void setCalificado(Usuario calificado) { this.calificado = calificado; }

    public TipoCalificacion getTipoCalificacion() { return tipoCalificacion; }
    public void setTipoCalificacion(TipoCalificacion tipoCalificacion) {
        this.tipoCalificacion = tipoCalificacion;
    }

    public Integer getPuntuacion() { return puntuacion; }
    public void setPuntuacion(Integer puntuacion) { this.puntuacion = puntuacion; }

    public String getComentario() { return comentario; }
    public void setComentario(String comentario) { this.comentario = comentario; }

    public LocalDateTime getFechaCalificacion() { return fechaCalificacion; }
    public void setFechaCalificacion(LocalDateTime fechaCalificacion) {
        this.fechaCalificacion = fechaCalificacion;
    }

    @Override
    public String toString() {
        return "Calificacion{" +
                "id=" + id +
                ", viajeId=" + (viaje != null ? viaje.getId() : null) +
                ", calificadorId=" + (calificador != null ? calificador.getId() : null) +
                ", calificadoId=" + (calificado != null ? calificado.getId() : null) +
                ", tipoCalificacion=" + tipoCalificacion +
                ", puntuacion=" + puntuacion +
                ", comentario='" + comentario + '\'' +
                ", fechaCalificacion=" + fechaCalificacion +
                '}';
    }
}

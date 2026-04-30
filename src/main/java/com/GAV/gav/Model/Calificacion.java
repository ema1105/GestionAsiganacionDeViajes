package com.GAV.gav.Model;


import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "calificacion")
public class Calificacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long Id;

    @ManyToOne
    private Viaje viaje;

    @ManyToOne
    @JoinColumn(name = "calificador_id")
    private Usuario calificador;

    @ManyToOne
    @JoinColumn(name = "calificado_id")
    private Usuario calificado;

    @Column(name = "puntuacion")
    private Integer puntuacion;

    @Column(name = "comentario")
    private String comentario;

    @Column(name = "fechaCailificacion")
    private LocalDateTime fechaCalificacion;


}

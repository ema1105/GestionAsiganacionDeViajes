package com.GAV.gav.Model;

import jakarta.persistence.*;

@Entity
@Table(name = "rol")
public class Rol {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    Long Id;

    @Column(unique = true)
    private String nombre;

    public Rol() {
    }

    public Rol(Long id, String nombre) {
        Id = id;
        this.nombre = nombre;
    }

    public Long getId() {
        return Id;
    }

    public void setId(Long id) {
        Id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    @Override
    public String
    toString() {
        return "Rol{" +
                "Id=" + Id +
                ", nombre='" + nombre + '\'' +
                '}';
    }
}

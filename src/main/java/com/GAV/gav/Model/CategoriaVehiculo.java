package com.GAV.gav.Model;


import jakarta.persistence.*;

@Entity
@Table(name = "categoria_vehiculo")
public class CategoriaVehiculo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long Id;


    private String nombre;


    private String descripcion;

    @ManyToOne
    @JoinColumn(name = "tarifa_id")
    private Tarifa tarifa;

    public CategoriaVehiculo() {
    }

    public CategoriaVehiculo(Long id, String nombre, String descripcion, Tarifa tarifa) {
        Id = id;
        this.nombre = nombre;
        this.descripcion = descripcion;
        this.tarifa = tarifa;
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

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public Tarifa getTarifa() {
        return tarifa;
    }

    public void setTarifa(Tarifa tarifa) {
        this.tarifa = tarifa;
    }

    @Override
    public String toString() {
        return "CategoriaVehiculo{" +
                "Id=" + Id +
                ", nombre='" + nombre + '\'' +
                ", descripcion='" + descripcion + '\'' +
                ", tarifa=" + tarifa +
                '}';
    }
}

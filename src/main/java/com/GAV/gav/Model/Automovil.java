package com.GAV.gav.Model;


import jakarta.persistence.*;

import java.util.Objects;

@Entity
@Table(name = "automovil")
public class Automovil {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long Id;

    private int capacidadMaxima;
    private String marca;
    private String modelo;
    private String placa;

    @ManyToOne
    @JoinColumn(name = "categoria_id")
    private CategoriaVehiculo categoria;

    public Automovil() {
    }

    public Automovil(Long id, int capacidadMaxima, String marca, String modelo, String placa, CategoriaVehiculo categoria) {
        Id = id;
        this.capacidadMaxima = capacidadMaxima;
        this.marca = marca;
        this.modelo = modelo;
        this.placa = placa;
        this.categoria = categoria;
    }

    public Long getId() {
        return Id;
    }

    public void setId(Long id) {
        Id = id;
    }

    public int getCapacidadMaxima() {
        return capacidadMaxima;
    }

    public void setCapacidadMaxima(int capacidadMaxima) {
        this.capacidadMaxima = capacidadMaxima;
    }

    public String getMarca() {
        return marca;
    }

    public void setMarca(String marca) {
        this.marca = marca;
    }

    public String getModelo() {
        return modelo;
    }

    public void setModelo(String modelo) {
        this.modelo = modelo;
    }

    public String getPlaca() {
        return placa;
    }

    public void setPlaca(String placa) {
        this.placa = placa;
    }

    public CategoriaVehiculo getCategoria() {
        return categoria;
    }

    public void setCategoria(CategoriaVehiculo categoria) {
        this.categoria = categoria;
    }

    @Override
    public String toString() {
        return "Automovil{" +
                "Id=" + Id +
                ", capacidadMaxima=" + capacidadMaxima +
                ", marca='" + marca + '\'' +
                ", modelo='" + modelo + '\'' +
                ", placa='" + placa + '\'' +
                ", categoria=" + categoria +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Automovil automovil = (Automovil) o;
        return Objects.equals(getId(), automovil.getId()) && Objects.equals(getPlaca(), automovil.getPlaca());
    }

    @Override
    public int hashCode() {
        return Objects.hash(getId(), getPlaca());
    }
}

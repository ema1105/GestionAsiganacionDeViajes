package com.GAV.gav.Model;


import jakarta.persistence.*;


import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "tarifa")
public class Tarifa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long Id;

    private BigDecimal precioBase;
    private BigDecimal precioPorKm;
    private BigDecimal precioPorMinuto;
    private BigDecimal multiplicadorDinamico;

    private LocalDateTime fechaInicio;
    private LocalDateTime fechaFin;
    private Boolean activo;


    public Tarifa() {
    }

    public Tarifa(Long id, BigDecimal precioBase, BigDecimal precioPorKm,
                  BigDecimal precioPorMinuto, BigDecimal multiplicadorDinamico,
                  LocalDateTime fechaInicio, LocalDateTime fechaFin, Boolean activo) {
        Id = id;
        this.precioBase = precioBase;
        this.precioPorKm = precioPorKm;
        this.precioPorMinuto = precioPorMinuto;
        this.multiplicadorDinamico = multiplicadorDinamico;
        this.fechaInicio = fechaInicio;
        this.fechaFin = fechaFin;
        this.activo = activo;
    }

    public Long getId() {
        return Id;
    }

    public void setId(Long id) {
        Id = id;
    }

    public BigDecimal getPrecioBase() {
        return precioBase;
    }

    public void setPrecioBase(BigDecimal precioBase) {
        this.precioBase = precioBase;
    }

    public BigDecimal getPrecioPorKm() {
        return precioPorKm;
    }

    public void setPrecioPorKm(BigDecimal precioPorKm) {
        this.precioPorKm = precioPorKm;
    }

    public BigDecimal getPrecioPorMinuto() {
        return precioPorMinuto;
    }

    public void setPrecioPorMinuto(BigDecimal precioPorMinuto) {
        this.precioPorMinuto = precioPorMinuto;
    }

    public BigDecimal getMultiplicadorDinamico() {
        return multiplicadorDinamico;
    }

    public void setMultiplicadorDinamico(BigDecimal multiplicadorDinamico) {
        this.multiplicadorDinamico = multiplicadorDinamico;
    }

    public LocalDateTime getFechaInicio() {
        return fechaInicio;
    }

    public void setFechaInicio(LocalDateTime fechaInicio) {
        this.fechaInicio = fechaInicio;
    }

    public LocalDateTime getFechaFin() {
        return fechaFin;
    }

    public void setFechaFin(LocalDateTime fechaFin) {
        this.fechaFin = fechaFin;
    }

    public Boolean getActivo() {
        return activo;
    }

    public void setActivo(Boolean activo) {
        this.activo = activo;
    }

    @Override
    public String toString() {
        return "Tarifa{" +
                "Id=" + Id +
                ", precioBase=" + precioBase +
                ", precioPorKm=" + precioPorKm +
                ", precioPorMinuto=" + precioPorMinuto +
                ", multiplicadorDinamico=" + multiplicadorDinamico +
                ", fechaInicio=" + fechaInicio +
                ", fechaFin=" + fechaFin +
                ", activo=" + activo +
                '}';
    }
}

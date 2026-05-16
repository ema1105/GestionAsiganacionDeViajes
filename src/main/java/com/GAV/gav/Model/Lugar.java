package com.GAV.gav.Model;

import jakarta.persistence.*;

import java.math.BigDecimal;

// Catálogo de puntos de interés de Cartagena de Indias y corregimientos aledaños.
// Sirve para: (1) vincular destinos de viajes a un lugar conocido y calcular
// "lugares más solicitados", y (2) alimentar (grounding) las sugerencias del chatbot.
@Entity
@Table(name = "lugar")
public class Lugar {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nombre", nullable = false)
    private String nombre;

    public enum Categoria {
        RESTAURANTE, MALL, PLAYA, HOTEL, AEROPUERTO,
        MUSEO, BAR, PARQUE, ZONA_HISTORICA, OTRO
    }

    @Enumerated(EnumType.STRING)
    @Column(name = "categoria")
    private Categoria categoria;

    @Column(name = "descripcion", length = 500)
    private String descripcion;

    // Texto libre con palabras clave para emparejar con lo que busca el cliente
    // (ej: "mariscos, comida de mar, ceviche, vista al mar").
    @Column(name = "etiquetas", length = 500)
    private String etiquetas;

    @Column(name = "lat")
    private BigDecimal lat;

    @Column(name = "lng")
    private BigDecimal lng;

    // Radio en metros para considerar que un destino "cae" en este lugar.
    @Column(name = "radioMetros")
    private Integer radioMetros = 200;

    // Nullable; NULL se trata como activo (mismo patrón que Conductor.activo).
    @Column(name = "activo")
    private Boolean activo = true;

    public Lugar() {}

    public Lugar(Long id, String nombre, Categoria categoria, String descripcion,
                 String etiquetas, BigDecimal lat, BigDecimal lng,
                 Integer radioMetros, Boolean activo) {
        this.id = id;
        this.nombre = nombre;
        this.categoria = categoria;
        this.descripcion = descripcion;
        this.etiquetas = etiquetas;
        this.lat = lat;
        this.lng = lng;
        this.radioMetros = radioMetros;
        this.activo = activo;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }

    public Categoria getCategoria() { return categoria; }
    public void setCategoria(Categoria categoria) { this.categoria = categoria; }

    public String getDescripcion() { return descripcion; }
    public void setDescripcion(String descripcion) { this.descripcion = descripcion; }

    public String getEtiquetas() { return etiquetas; }
    public void setEtiquetas(String etiquetas) { this.etiquetas = etiquetas; }

    public BigDecimal getLat() { return lat; }
    public void setLat(BigDecimal lat) { this.lat = lat; }

    public BigDecimal getLng() { return lng; }
    public void setLng(BigDecimal lng) { this.lng = lng; }

    public Integer getRadioMetros() { return radioMetros; }
    public void setRadioMetros(Integer radioMetros) { this.radioMetros = radioMetros; }

    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean activo) { this.activo = activo; }

    @Override
    public String toString() {
        return "Lugar{id=" + id + ", nombre='" + nombre + "', categoria=" + categoria + '}';
    }
}

package com.GAV.gav.Model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "viaje")
public class Viaje {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "cantidadPasajeros")
    private int cantidadPasajeros;

    @Column(name = "origenLat")
    private BigDecimal origenLat;

    @Column(name = "origenLng")
    private BigDecimal origenLng;

    @Column(name = "destinoLat")
    private BigDecimal destinoLat;

    @Column(name = "destinoLng")
    private BigDecimal destinoLng;

    public enum EstadoViaje {
        SOLICITADO, BUSCANDO_CONDUCTOR,
        ACEPTADO, EN_CAMINO, EN_CURSO,
        FINALIZADO,  // conductor marcó el viaje como terminado → conductor vuelve al pool FIFO
        CANCELADO    // cliente o admin canceló el viaje
    }
    @Enumerated(EnumType.STRING)
    private EstadoViaje estadoViaje;

    @ManyToOne
    @JoinColumn(name = "cliente_id")
    private Usuario cliente;

    @ManyToOne
    @JoinColumn(name = "conductor_id")
    private Usuario conductor;

    @ManyToOne
    @JoinColumn(name = "automovil_id")
    private Automovil automovil;

    // NUEVO: lugar del catálogo al que corresponde el destino (si las coordenadas
    // caen dentro del radio de un POI conocido). Nullable: viajes sin match quedan en null.
    // Se usa para calcular "lugares más solicitados".
    @ManyToOne
    @JoinColumn(name = "lugar_destino_id")
    private Lugar lugarDestino;

    @Column(name = "precio")
    private BigDecimal precio;

    @Column(name = "precioCalculado")
    private BigDecimal precioCalculado;

    @Column(name = "fechaSolicitud")
    private LocalDateTime fechaSolicitud;

    @Column(name = "fechaInicio")
    private LocalDateTime fechaInicio;

    @Column(name = "fechaFinalizacion")
    private LocalDateTime fechaFinalizacion;


    public Viaje() {
    }

    public Viaje(Long id, int cantidadPasajeros, BigDecimal origenLat, BigDecimal origenLng,
                 BigDecimal destinoLat, BigDecimal destinoLng, EstadoViaje estadoViaje,
                 Usuario cliente, Usuario conductor, Automovil automovil,
                 BigDecimal precio, BigDecimal precioCalculado, LocalDateTime fechaSolicitud,
                 LocalDateTime fechaInicio, LocalDateTime fechaFinalizacion) {
        this.id = id;
        this.cantidadPasajeros = cantidadPasajeros;
        this.origenLat = origenLat;
        this.origenLng = origenLng;
        this.destinoLat = destinoLat;
        this.destinoLng = destinoLng;
        this.estadoViaje = estadoViaje;
        this.cliente = cliente;
        this.conductor = conductor;
        this.automovil = automovil;
        this.precio = precio;
        this.precioCalculado = precioCalculado;
        this.fechaSolicitud = fechaSolicitud;
        this.fechaInicio = fechaInicio;
        this.fechaFinalizacion = fechaFinalizacion;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public int getCantidadPasajeros() {
        return cantidadPasajeros;
    }

    public void setCantidadPasajeros(int cantidadPasajeros) {
        this.cantidadPasajeros = cantidadPasajeros;
    }

    public BigDecimal getOrigenLat() {
        return origenLat;
    }

    public void setOrigenLat(BigDecimal origenLat) {
        this.origenLat = origenLat;
    }

    public BigDecimal getOrigenLng() {
        return origenLng;
    }

    public void setOrigenLng(BigDecimal origenLng) {
        this.origenLng = origenLng;
    }

    public BigDecimal getDestinoLat() {
        return destinoLat;
    }

    public void setDestinoLat(BigDecimal destinoLat) {
        this.destinoLat = destinoLat;
    }

    public BigDecimal getDestinoLng() {
        return destinoLng;
    }

    public void setDestinoLng(BigDecimal destinoLng) {
        this.destinoLng = destinoLng;
    }

    public EstadoViaje getEstadoViaje() {
        return estadoViaje;
    }

    public void setEstadoViaje(EstadoViaje estadoViaje) {
        this.estadoViaje = estadoViaje;
    }

    public Usuario getCliente() {
        return cliente;
    }

    public void setCliente(Usuario cliente) {
        this.cliente = cliente;
    }

    public Usuario getConductor() {
        return conductor;
    }

    public void setConductor(Usuario conductor) {
        this.conductor = conductor;
    }

    public Automovil getAutomovil() {
        return automovil;
    }

    public void setAutomovil(Automovil automovil) {
        this.automovil = automovil;
    }

    public Lugar getLugarDestino() {
        return lugarDestino;
    }

    public void setLugarDestino(Lugar lugarDestino) {
        this.lugarDestino = lugarDestino;
    }

    public BigDecimal getPrecio() {
        return precio;
    }

    public void setPrecio(BigDecimal precio) {
        this.precio = precio;
    }

    public BigDecimal getPrecioCalculado() {
        return precioCalculado;
    }

    public void setPrecioCalculado(BigDecimal precioCalculado) {
        this.precioCalculado = precioCalculado;
    }

    public LocalDateTime getFechaSolicitud() {
        return fechaSolicitud;
    }

    public void setFechaSolicitud(LocalDateTime fechaSolicitud) {
        this.fechaSolicitud = fechaSolicitud;
    }

    public LocalDateTime getFechaInicio() {
        return fechaInicio;
    }

    public void setFechaInicio(LocalDateTime fechaInicio) {
        this.fechaInicio = fechaInicio;
    }

    public LocalDateTime getFechaFinalizacion() {
        return fechaFinalizacion;
    }

    public void setFechaFinalizacion(LocalDateTime fechaFinalizacion) {
        this.fechaFinalizacion = fechaFinalizacion;
    }


    @Override
    public String toString() {
        return "Viaje{" +
                "id=" + id +
                ", cantidadPasajeros=" + cantidadPasajeros +
                ", origenLat=" + origenLat +
                ", origenLng=" + origenLng +
                ", destinoLat=" + destinoLat +
                ", destinoLng=" + destinoLng +
                ", estadoViaje=" + estadoViaje +
                ", cliente=" + cliente +
                ", conductor=" + conductor +
                ", automovil=" + automovil +
                ", precio=" + precio +
                ", precioCalculado=" + precioCalculado +
                ", fechaSolicitud=" + fechaSolicitud +
                ", fechaInicio=" + fechaInicio +
                ", fechaFinalizacion=" + fechaFinalizacion +
                '}';
    }
}

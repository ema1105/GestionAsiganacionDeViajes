package com.GAV.gav.Model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

@Entity
@Table(name = "conductor")
public class Conductor {

    @Id
    private Long usuarioId;

    @OneToOne
    @MapsId
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @Column(name = "disponibilidad")
    private Boolean disponibilidad;

    @Column(name = "licencia", unique = true, nullable = false)
    private String licencia;

    public enum TipoLicencia {
        A1, A2,
        B1, B2, B3,
        C1, C2, C3
    }

    @Enumerated(EnumType.STRING)
    private TipoLicencia tipoLicencia;

    @OneToOne
    @JoinColumn(name = "automovil_id")
    private Automovil automovil;

    // NUEVO: timestamp clave para el algoritmo FIFO de asignación de viajes.
    // Se asigna en dos momentos: cuando el conductor se registra (queda disponible)
    // y cuando finaliza un viaje (vuelve a estar disponible).
    // Se pone null cuando acepta un viaje, indicando que ya no está en la cola.
    // El conductor con la fecha más antigua tiene máxima prioridad en el FIFO.
    @Column(name = "fechaDisponibleDesde")
    private LocalDateTime fechaDisponibleDesde;

    // soft-delete. Cuando el admin "deshabilita" un conductor (renuncia,
    // baja del hotel) se pone en false. El registro y sus viajes históricos
    // permanecen en BD para auditoría, pero:
    //   - No aparece en listados de admin/cliente
    //   - No entra al pool FIFO
    //   - No puede iniciar sesión (UserDetailsServiceImpl lo marca disabled)
    // Nullable para no romper registros preexistentes; el código trata NULL como true.
    @Column(name = "activo")
    private Boolean activo = true;

    // Última señal de vida de la app del conductor (polling de solicitudes o GPS).
    // El FIFO solo ofrece viajes a conductores con señal reciente (conectados);
    // así no se pierden 30 s por cada conductor que tiene la app cerrada.
    @Column(name = "ultimaConexion")
    private LocalDateTime ultimaConexion;

    // Última posición GPS reportada (copia de la última fila de ubicacion_conductor).
    // Permite que el mapa "Flota en vivo" lea una fila por conductor.
    @Column(name = "ultimaLat", precision = 10, scale = 7)
    private BigDecimal ultimaLat;

    @Column(name = "ultimaLng", precision = 10, scale = 7)
    private BigDecimal ultimaLng;

    @Column(name = "ultimaUbicacionEn")
    private LocalDateTime ultimaUbicacionEn;

    public BigDecimal getUltimaLat() { return ultimaLat; }
    public void setUltimaLat(BigDecimal ultimaLat) { this.ultimaLat = ultimaLat; }
    public BigDecimal getUltimaLng() { return ultimaLng; }
    public void setUltimaLng(BigDecimal ultimaLng) { this.ultimaLng = ultimaLng; }
    public LocalDateTime getUltimaUbicacionEn() { return ultimaUbicacionEn; }
    public void setUltimaUbicacionEn(LocalDateTime ultimaUbicacionEn) { this.ultimaUbicacionEn = ultimaUbicacionEn; }

    public LocalDateTime getUltimaConexion() { return ultimaConexion; }
    public void setUltimaConexion(LocalDateTime ultimaConexion) { this.ultimaConexion = ultimaConexion; }

    public Conductor() {}

    public Conductor(Long usuarioId, Usuario usuario, Boolean disponibilidad, String licencia,
                     TipoLicencia tipoLicencia, Automovil automovil, LocalDateTime fechaDisponibleDesde) {
        this.usuarioId = usuarioId;
        this.usuario = usuario;
        this.disponibilidad = disponibilidad;
        this.licencia = licencia;
        this.tipoLicencia = tipoLicencia;
        this.automovil = automovil;
        this.fechaDisponibleDesde = fechaDisponibleDesde;
        this.activo = true;
    }

    public Long getUsuarioId() { return usuarioId; }
    public void setUsuarioId(Long usuarioId) { this.usuarioId = usuarioId; }

    public Usuario getUsuario() { return usuario; }
    public void setUsuario(Usuario usuario) { this.usuario = usuario; }

    public Boolean getDisponibilidad() { return disponibilidad; }
    public void setDisponibilidad(Boolean disponibilidad) { this.disponibilidad = disponibilidad; }

    public String getLicencia() { return licencia; }
    public void setLicencia(String licencia) { this.licencia = licencia; }

    public TipoLicencia getTipoLicencia() { return tipoLicencia; }
    public void setTipoLicencia(TipoLicencia tipoLicencia) { this.tipoLicencia = tipoLicencia; }

    public Automovil getAutomovil() { return automovil; }
    public void setAutomovil(Automovil automovil) { this.automovil = automovil; }

    public LocalDateTime getFechaDisponibleDesde() { return fechaDisponibleDesde; }
    public void setFechaDisponibleDesde(LocalDateTime fechaDisponibleDesde) {
        this.fechaDisponibleDesde = fechaDisponibleDesde;
    }

    // NULL en BD se trata como activo (compatibilidad con registros pre-existentes).
    public Boolean getActivo() { return activo; }
    public void setActivo(Boolean activo) { this.activo = activo; }

    public boolean isActivoEffective() {
        return activo == null || Boolean.TRUE.equals(activo);
    }

    @Override
    public String toString() {
        return "Conductor{" +
                "usuarioId=" + usuarioId +
                ", usuario=" + usuario +
                ", disponibilidad=" + disponibilidad +
                ", licencia='" + licencia + '\'' +
                ", tipoLicencia=" + tipoLicencia +
                ", automovil=" + automovil +
                ", fechaDisponibleDesde=" + fechaDisponibleDesde +
                ", activo=" + activo +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Conductor conductor = (Conductor) o;
        return Objects.equals(getUsuarioId(), conductor.getUsuarioId()) &&
               Objects.equals(getUsuario(), conductor.getUsuario()) &&
               Objects.equals(getLicencia(), conductor.getLicencia());
    }

    @Override
    public int hashCode() {
        return Objects.hash(getUsuarioId(), getUsuario(), getLicencia());
    }
}

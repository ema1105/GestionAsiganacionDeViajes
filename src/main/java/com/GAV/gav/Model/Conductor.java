package com.GAV.gav.Model;

import jakarta.persistence.*;
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

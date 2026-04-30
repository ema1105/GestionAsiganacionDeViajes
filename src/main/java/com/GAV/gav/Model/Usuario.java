package com.GAV.gav.Model;
import jakarta.persistence.*;
import java.util.Date;
import java.util.Objects;


@Entity
@Table(name="usuario")
public class Usuario {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "nombreCompleto", nullable = false)
    private String nombreCompleto;

    @Column(name = "apellidosCompletos", nullable = false)
    private String apellidosCompletos;

    @Column(name = "fechaNacimiento", nullable = false)
    private Date fechaNacimiento;

    @Column(name = "nombrUsuario", nullable = false)
    private String nombreUsuario;

    @Column(name = "contrasena", nullable = false)
    private String contrasena;

    @Column(name = "telefono", nullable = false)
    private String telefono;


    // CAMBIO: visibilidad cambiada de private a public
    // Necesario para que RegisterClienteRequest y RegisterConductorRequest puedan exponerlo
    public enum TipoDocumento {
        CC, TI,
        PASAPORTE, CE,
        PERMISO_PERMANECIA
    }
    @Enumerated(EnumType.STRING)
    private TipoDocumento tipoDocumento;

    @Column(name = "numeroDocumento", nullable = false)
    private String numeroDocumento;


    @Column(name = "correo", nullable = false)
    private String email;

    @ManyToOne
    @JoinColumn(name = "rol_id")
    private Rol rol;


    public Usuario() {
    }

    public Usuario(Long id, String nombreCompleto, String apellidosCompletos, Date fechaNacimiento,
                   String nombreUsuario, String contrasena, String telefono, TipoDocumento tipoDocumento,
                   String numeroDocumento, String email, Rol rol) {
        this.id = id;
        this.nombreCompleto = nombreCompleto;
        this.apellidosCompletos = apellidosCompletos;
        this.fechaNacimiento = fechaNacimiento;
        this.nombreUsuario = nombreUsuario;
        this.contrasena = contrasena;
        this.telefono = telefono;
        this.tipoDocumento = tipoDocumento;
        this.numeroDocumento = numeroDocumento;
        this.email = email;
        this.rol = rol;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNombreCompleto() {
        return nombreCompleto;
    }

    public void setNombreCompleto(String nombreCompleto) {
        this.nombreCompleto = nombreCompleto;
    }

    public String getApellidosCompletos() {
        return apellidosCompletos;
    }

    public void setApellidosCompletos(String apellidosCompletos) {
        this.apellidosCompletos = apellidosCompletos;
    }

    public Date getFechaNacimiento() {
        return fechaNacimiento;
    }

    public void setFechaNacimiento(Date fechaNacimiento) {
        this.fechaNacimiento = fechaNacimiento;
    }

    public String getNombreUsuario() {
        return nombreUsuario;
    }

    public void setNombreUsuario(String nombreUsuario) {
        this.nombreUsuario = nombreUsuario;
    }

    public String getContrasena() {
        return contrasena;
    }

    public void setContrasena(String contrasena) {
        this.contrasena = contrasena;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono;
    }

    public TipoDocumento getTipoDocumento() {
        return tipoDocumento;
    }

    public void setTipoDocumento(TipoDocumento tipoDocumento) {
        this.tipoDocumento = tipoDocumento;
    }

    public String getEmail(){
        return email;
    }

    public void setEmail(String email){
        this.email = email;
    }

    public String getNumeroDocumento() {
        return numeroDocumento;
    }

    public void setNumeroDocumento(String numeroDocumento) {
        this.numeroDocumento = numeroDocumento;
    }

    public Rol getRol() {
        return rol;
    }

    public void setRol(Rol rol) {
        this.rol = rol;
    }

    @Override
    public String toString() {
        return "usuario{" +
                "id=" + id +
                ", nombreCompleto='" + nombreCompleto + '\'' +
                ", apellidosCompletos='" + apellidosCompletos + '\'' +
                ", fechaNacimiento=" + fechaNacimiento +
                ", nombreUsuario='" + nombreUsuario + '\'' +
                ", contrasena='" + contrasena + '\'' +
                ", telefono='" + telefono + '\'' +
                ", tipoDocumento=" + tipoDocumento +
                ", email=" + email +
                ", numeroDocumento=" +numeroDocumento +
                ", rol" + rol +
                '}';
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Usuario usuario = (Usuario) o;
        return Objects.equals(getId(), usuario.getId()) && Objects.equals(getNombreUsuario(),
                usuario.getNombreUsuario()) && Objects.equals(getTelefono(), usuario.getTelefono()) && Objects.equals(getNumeroDocumento(),
                usuario.getNumeroDocumento()) && Objects.equals(getEmail(), usuario.getEmail());
    }

    @Override
    public int hashCode() {
        return Objects.hash(getId(), getNombreUsuario(), getTelefono(), getNumeroDocumento(), getEmail());
    }
}




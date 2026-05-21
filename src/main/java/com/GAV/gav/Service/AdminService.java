package com.GAV.gav.Service;

import com.GAV.gav.DTO.Request.ActualizarConductorRequest;
import com.GAV.gav.DTO.Request.ActualizarPerfilAdminRequest;
import com.GAV.gav.DTO.Request.ActualizarVehiculoRequest;
import com.GAV.gav.DTO.Request.CrearVehiculoRequest;
import com.GAV.gav.DTO.Request.RegisterConductorRequest;
import com.GAV.gav.DTO.Response.*;
import com.GAV.gav.Exception.BusinessException;
import com.GAV.gav.Model.*;
import com.GAV.gav.Repository.*;
import com.GAV.gav.Security.AuthenticatedUserProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

// Lógica exclusiva del rol ADMIN.
// Cubre: CRUD conductores (con soft-delete), CRUD vehículos (hard-delete),
// asociación conductor↔vehículo, historial paginado de viajes y estadísticas.
@Service
@RequiredArgsConstructor
public class AdminService {

    private final UsuarioRepository usuarioRepository;
    private final RolRepository rolRepository;
    private final ConductorRepository conductorRepository;
    private final AutomovilRepository automovilRepository;
    private final CategoriaVehiculoRepository categoriaVehiculoRepository;
    private final ViajeRepository viajeRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticatedUserProvider userProvider;

    // ========================================================================
    // CONDUCTORES — registro, listado, modificación, soft-delete, hard-delete
    // ========================================================================

    @Transactional
    public ConductorResponse registrarConductor(RegisterConductorRequest request) {
        validarCamposUnicos(request.getEmail(), request.getTelefono(),
                request.getNumeroDocumento(), request.getNombreUsuario());

        Rol rolConductor = rolRepository.findByNombre("ROLE_CONDUCTOR")
                .orElseThrow(() -> new BusinessException(
                        "Rol ROLE_CONDUCTOR no encontrado. Contacte al administrador.",
                        HttpStatus.INTERNAL_SERVER_ERROR));

        CategoriaVehiculo categoria = categoriaVehiculoRepository
                .findById(request.getCategoriaVehiculoId())
                .orElseThrow(() -> new BusinessException(
                        "Categoría de vehículo no encontrada: " + request.getCategoriaVehiculoId(),
                        HttpStatus.BAD_REQUEST));

        // Paso 1: usuario base
        Usuario usuario = new Usuario();
        usuario.setNombreCompleto(request.getNombreCompleto());
        usuario.setApellidosCompletos(request.getApellidosCompletos());
        usuario.setFechaNacimiento(request.getFechaNacimiento());
        usuario.setNombreUsuario(request.getNombreUsuario());
        usuario.setContrasena(passwordEncoder.encode(request.getContrasena()));
        usuario.setTelefono(request.getTelefono());
        usuario.setTipoDocumento(request.getTipoDocumento());
        usuario.setNumeroDocumento(request.getNumeroDocumento());
        usuario.setEmail(request.getEmail());
        usuario.setRol(rolConductor);
        Usuario usuarioGuardado = usuarioRepository.save(usuario);

        // Paso 2: vehículo
        Automovil automovil = new Automovil();
        automovil.setMarca(request.getMarcaVehiculo());
        automovil.setModelo(request.getModeloVehiculo());
        automovil.setPlaca(request.getPlacaVehiculo());
        automovil.setCapacidadMaxima(request.getCapacidadMaxima());
        automovil.setCategoria(categoria);
        Automovil automovilGuardado = automovilRepository.save(automovil);

        // Paso 3: conductor (activo=true por default, entra al pool FIFO)
        Conductor conductor = new Conductor(
                null,
                usuarioGuardado,
                true,
                request.getLicencia(),
                request.getTipoLicencia(),
                automovilGuardado,
                LocalDateTime.now()
        );
        conductor.setActivo(true);
        Conductor conductorGuardado = conductorRepository.save(conductor);

        return mapToConductorResponse(conductorGuardado);
    }

    // Listado con filtros opcionales. Por default solo activos; si incluirInactivos=true
    // devuelve todos (incluyendo deshabilitados).
    public List<ConductorResponse> listarConductores(Boolean disponibilidad,
                                                      Conductor.TipoLicencia tipoLicencia,
                                                      boolean incluirInactivos) {
        return conductorRepository.findConFiltros(disponibilidad, tipoLicencia, incluirInactivos)
                .stream()
                .map(this::mapToConductorResponse)
                .toList();
    }

    public ConductorResponse obtenerConductor(Long usuarioId) {
        Conductor c = conductorRepository.findById(usuarioId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + usuarioId, HttpStatus.NOT_FOUND));
        return mapToConductorResponse(c);
    }

    @Transactional
    public ConductorResponse actualizarConductor(Long usuarioId, ActualizarConductorRequest req) {
        Conductor conductor = conductorRepository.findById(usuarioId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + usuarioId, HttpStatus.NOT_FOUND));
        Usuario usuario = conductor.getUsuario();

        // Datos de Usuario (solo si vienen no-null)
        if (req.getNombreCompleto() != null)       usuario.setNombreCompleto(req.getNombreCompleto());
        if (req.getApellidosCompletos() != null)   usuario.setApellidosCompletos(req.getApellidosCompletos());
        if (req.getFechaNacimiento() != null)      usuario.setFechaNacimiento(req.getFechaNacimiento());
        if (req.getTelefono() != null)             usuario.setTelefono(req.getTelefono());
        if (req.getEmail() != null)                usuario.setEmail(req.getEmail());
        if (req.getTipoDocumento() != null)        usuario.setTipoDocumento(req.getTipoDocumento());
        if (req.getNumeroDocumento() != null)      usuario.setNumeroDocumento(req.getNumeroDocumento());
        if (req.getContrasena() != null && !req.getContrasena().isBlank()) {
            usuario.setContrasena(passwordEncoder.encode(req.getContrasena()));
        }
        usuarioRepository.save(usuario);

        // Datos de Conductor
        if (req.getLicencia() != null)      conductor.setLicencia(req.getLicencia());
        if (req.getTipoLicencia() != null)  conductor.setTipoLicencia(req.getTipoLicencia());
        Conductor actualizado = conductorRepository.save(conductor);

        return mapToConductorResponse(actualizado);
    }

    // Soft-delete: el conductor permanece en BD con sus viajes históricos accesibles,
    // pero queda fuera del FIFO, no aparece en listados (a menos que se pida explícito)
    // y no puede iniciar sesión.
    @Transactional
    public ConductorResponse deshabilitarConductor(Long usuarioId) {
        Conductor c = conductorRepository.findById(usuarioId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + usuarioId, HttpStatus.NOT_FOUND));

        c.setActivo(false);
        c.setDisponibilidad(false);
        c.setFechaDisponibleDesde(null);   // sale del pool FIFO
        return mapToConductorResponse(conductorRepository.save(c));
    }

    @Transactional
    public ConductorResponse habilitarConductor(Long usuarioId) {
        Conductor c = conductorRepository.findById(usuarioId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + usuarioId, HttpStatus.NOT_FOUND));

        c.setActivo(true);
        c.setDisponibilidad(true);
        c.setFechaDisponibleDesde(LocalDateTime.now());   // entra al pool FIFO
        return mapToConductorResponse(conductorRepository.save(c));
    }

    // Hard-delete. Si tiene viajes asociados, MySQL FK lanzará DataIntegrityViolationException
    // que el GlobalExceptionHandler mapea a 409.
    @Transactional
    public void eliminarConductor(Long usuarioId) {
        Conductor c = conductorRepository.findById(usuarioId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + usuarioId, HttpStatus.NOT_FOUND));

        Long usuarioBackingId = c.getUsuario() != null ? c.getUsuario().getId() : null;
        conductorRepository.delete(c);
        // Borramos también el Usuario base para no dejar huérfanos sin rol funcional
        if (usuarioBackingId != null) {
            usuarioRepository.deleteById(usuarioBackingId);
        }
    }

    // ========================================================================
    // VEHÍCULOS — CRUD completo + asociación
    // ========================================================================

    @Transactional
    public VehiculoResponse crearVehiculo(CrearVehiculoRequest req) {
        if (automovilRepository.existsByPlaca(req.getPlaca())) {
            throw new BusinessException(
                    "Ya existe un vehículo con placa: " + req.getPlaca(), HttpStatus.CONFLICT);
        }
        CategoriaVehiculo categoria = categoriaVehiculoRepository.findById(req.getCategoriaVehiculoId())
                .orElseThrow(() -> new BusinessException(
                        "Categoría no encontrada: " + req.getCategoriaVehiculoId(),
                        HttpStatus.BAD_REQUEST));

        Automovil a = new Automovil();
        a.setMarca(req.getMarca());
        a.setModelo(req.getModelo());
        a.setPlaca(req.getPlaca());
        a.setCapacidadMaxima(req.getCapacidadMaxima());
        a.setCategoria(categoria);
        return mapToVehiculoResponse(automovilRepository.save(a));
    }

    public List<VehiculoResponse> listarVehiculos() {
        return automovilRepository.findAll()
                .stream()
                .map(this::mapToVehiculoResponse)
                .toList();
    }

    // Listado de clientes (usuarios con ROLE_CLIENTE) para el panel admin.
    // Incluye el total de viajes de cada cliente.
    public List<java.util.Map<String, Object>> listarClientes() {
        return usuarioRepository.findByRol_Nombre("ROLE_CLIENTE")
                .stream()
                .map(u -> {
                    java.util.Map<String, Object> m = new java.util.LinkedHashMap<>();
                    m.put("id", u.getId());
                    m.put("nombreCompleto", u.getNombreCompleto());
                    m.put("apellidosCompletos", u.getApellidosCompletos());
                    m.put("email", u.getEmail());
                    m.put("telefono", u.getTelefono());
                    m.put("totalViajes", viajeRepository.countByClienteId(u.getId()));
                    return m;
                })
                .toList();
    }

    // Categorías de vehículo para poblar el selector del formulario de
    // registro de conductor en el panel admin. Devuelve id + nombre + descripción.
    public List<java.util.Map<String, Object>> listarCategorias() {
        return categoriaVehiculoRepository.findAll()
                .stream()
                .map(c -> {
                    java.util.Map<String, Object> m = new java.util.LinkedHashMap<>();
                    m.put("id", c.getId());
                    m.put("nombre", c.getNombre());
                    m.put("descripcion", c.getDescripcion());
                    return m;
                })
                .toList();
    }

    public VehiculoResponse obtenerVehiculo(Long id) {
        Automovil a = automovilRepository.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "Vehículo no encontrado: " + id, HttpStatus.NOT_FOUND));
        return mapToVehiculoResponse(a);
    }

    @Transactional
    public VehiculoResponse actualizarVehiculo(Long id, ActualizarVehiculoRequest req) {
        Automovil a = automovilRepository.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "Vehículo no encontrado: " + id, HttpStatus.NOT_FOUND));

        if (req.getMarca() != null)            a.setMarca(req.getMarca());
        if (req.getModelo() != null)           a.setModelo(req.getModelo());
        if (req.getPlaca() != null && !req.getPlaca().equals(a.getPlaca())) {
            if (automovilRepository.existsByPlaca(req.getPlaca())) {
                throw new BusinessException(
                        "Ya existe un vehículo con placa: " + req.getPlaca(),
                        HttpStatus.CONFLICT);
            }
            a.setPlaca(req.getPlaca());
        }
        if (req.getCapacidadMaxima() != null)  a.setCapacidadMaxima(req.getCapacidadMaxima());
        if (req.getCategoriaVehiculoId() != null) {
            CategoriaVehiculo cat = categoriaVehiculoRepository.findById(req.getCategoriaVehiculoId())
                    .orElseThrow(() -> new BusinessException(
                            "Categoría no encontrada: " + req.getCategoriaVehiculoId(),
                            HttpStatus.BAD_REQUEST));
            a.setCategoria(cat);
        }
        return mapToVehiculoResponse(automovilRepository.save(a));
    }

    @Transactional
    public void eliminarVehiculo(Long id) {
        Automovil a = automovilRepository.findById(id)
                .orElseThrow(() -> new BusinessException(
                        "Vehículo no encontrado: " + id, HttpStatus.NOT_FOUND));
        // Si tiene FKs, MySQL lanza DataIntegrityViolationException → mapeado a 409
        automovilRepository.delete(a);
    }

    // Asocia un vehículo a un conductor. Reemplaza la asociación previa si existía.
    @Transactional
    public ConductorResponse asociarVehiculo(Long conductorId, Long vehiculoId) {
        Conductor conductor = conductorRepository.findById(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));
        Automovil vehiculo = automovilRepository.findById(vehiculoId)
                .orElseThrow(() -> new BusinessException(
                        "Vehículo no encontrado: " + vehiculoId, HttpStatus.NOT_FOUND));

        conductor.setAutomovil(vehiculo);
        return mapToConductorResponse(conductorRepository.save(conductor));
    }

    @Transactional
    public ConductorResponse desasociarVehiculo(Long conductorId) {
        Conductor conductor = conductorRepository.findById(conductorId)
                .orElseThrow(() -> new BusinessException(
                        "Conductor no encontrado: " + conductorId, HttpStatus.NOT_FOUND));
        conductor.setAutomovil(null);
        return mapToConductorResponse(conductorRepository.save(conductor));
    }

    // ========================================================================
    // HISTORIAL DE VIAJES — paginación + filtros
    // ========================================================================

    public PageResponse<ViajeResponse> listarViajes(
            Viaje.EstadoViaje estado,
            Long clienteId,
            Long conductorId,
            LocalDateTime desde,
            LocalDateTime hasta,
            int page,
            int size) {

        Pageable pageable = PageRequest.of(page, size);
        Page<Viaje> resultado = viajeRepository.findConFiltros(
                estado, clienteId, conductorId, desde, hasta, pageable);

        return PageResponse.from(resultado, this::mapToViajeResponse);
    }

    // ========================================================================
    // ESTADÍSTICAS — ganancias y conteo de viajes
    // ========================================================================

    public GananciasResponse gananciasDelDia(LocalDate fecha) {
        LocalDateTime desde = fecha.atStartOfDay();
        LocalDateTime hasta = fecha.atTime(LocalTime.MAX);
        return calcularGanancias(fecha.toString(), desde, hasta);
    }

    public GananciasResponse gananciasDelMes(int anio, int mes) {
        YearMonth ym = YearMonth.of(anio, mes);
        LocalDateTime desde = ym.atDay(1).atStartOfDay();
        LocalDateTime hasta = ym.atEndOfMonth().atTime(LocalTime.MAX);
        String periodo = String.format("%04d-%02d", anio, mes);
        return calcularGanancias(periodo, desde, hasta);
    }

    private GananciasResponse calcularGanancias(String periodo,
                                                 LocalDateTime desde,
                                                 LocalDateTime hasta) {
        BigDecimal total = viajeRepository.sumarGanancias(desde, hasta);
        long count = viajeRepository.contarViajesFinalizados(desde, hasta);
        return GananciasResponse.builder()
                .periodo(periodo)
                .desde(desde)
                .hasta(hasta)
                .total(total != null ? total : BigDecimal.ZERO)
                .cantidadViajes(count)
                .build();
    }

    // Cantidad total de viajes solicitados en un día (cualquier estado).
    public long viajesDelDia(LocalDate fecha) {
        LocalDateTime desde = fecha.atStartOfDay();
        LocalDateTime hasta = fecha.atTime(LocalTime.MAX);
        List<Object[]> filas = viajeRepository.contarViajesPorDia(desde, hasta);
        if (filas.isEmpty()) return 0L;
        Object[] row = filas.get(0);
        return ((Number) row[1]).longValue();
    }

    // Serie temporal: cantidad de viajes por día en un rango.
    public List<ViajesPorDiaResponse> viajesPorDia(LocalDate desde, LocalDate hasta) {
        LocalDateTime ini = desde.atStartOfDay();
        LocalDateTime fin = hasta.atTime(LocalTime.MAX);
        List<Object[]> filas = viajeRepository.contarViajesPorDia(ini, fin);

        List<ViajesPorDiaResponse> resultado = new ArrayList<>();
        for (Object[] row : filas) {
            // row[0] = java.sql.Date, row[1] = Number
            Date sqlDate = (Date) row[0];
            long cantidad = ((Number) row[1]).longValue();
            resultado.add(ViajesPorDiaResponse.builder()
                    .fecha(sqlDate.toLocalDate())
                    .cantidad(cantidad)
                    .build());
        }
        return resultado;
    }

    // ========================================================================
    // PERFIL DEL ADMINISTRADOR
    // ========================================================================

    public UsuarioResponse obtenerPerfilAdmin() {
        Usuario usuario = userProvider.getCurrentUser();
        return mapToUsuarioResponse(usuario);
    }

    @Transactional
    public UsuarioResponse actualizarPerfilAdmin(ActualizarPerfilAdminRequest req) {
        Usuario usuario = userProvider.getCurrentUser();

        if (req.getEmail() != null && !req.getEmail().isBlank()) {
            // Verificar unicidad solo si cambia el correo
            if (!req.getEmail().equalsIgnoreCase(usuario.getEmail())
                    && usuarioRepository.existsByEmail(req.getEmail())) {
                throw new BusinessException("El correo ya está registrado por otro usuario.",
                        HttpStatus.CONFLICT);
            }
            usuario.setEmail(req.getEmail());
        }
        if (req.getTelefono() != null && !req.getTelefono().isBlank()) {
            if (!req.getTelefono().equals(usuario.getTelefono())
                    && usuarioRepository.existsByTelefono(req.getTelefono())) {
                throw new BusinessException("El teléfono ya está registrado por otro usuario.",
                        HttpStatus.CONFLICT);
            }
            usuario.setTelefono(req.getTelefono());
        }
        if (req.getContrasena() != null && !req.getContrasena().isBlank()) {
            usuario.setContrasena(passwordEncoder.encode(req.getContrasena()));
        }

        return mapToUsuarioResponse(usuarioRepository.save(usuario));
    }

    // ========================================================================
    // Helpers de mapeo y validación
    // ========================================================================

    private void validarCamposUnicos(String email, String telefono,
                                      String numeroDocumento, String nombreUsuario) {
        if (usuarioRepository.existsByEmail(email))
            throw new BusinessException("El correo ya está registrado.", HttpStatus.CONFLICT);
        if (usuarioRepository.existsByTelefono(telefono))
            throw new BusinessException("El teléfono ya está registrado.", HttpStatus.CONFLICT);
        if (usuarioRepository.existsByNumeroDocumento(numeroDocumento))
            throw new BusinessException("El número de documento ya está registrado.", HttpStatus.CONFLICT);
        if (usuarioRepository.existsByNombreUsuario(nombreUsuario))
            throw new BusinessException("El nombre de usuario ya está en uso.", HttpStatus.CONFLICT);
    }

    private UsuarioResponse mapToUsuarioResponse(Usuario u) {
        return UsuarioResponse.builder()
                .id(u.getId())
                .nombreCompleto(u.getNombreCompleto())
                .apellidosCompletos(u.getApellidosCompletos())
                .nombreUsuario(u.getNombreUsuario())
                .email(u.getEmail())
                .telefono(u.getTelefono())
                .tipoDocumento(u.getTipoDocumento())
                .numeroDocumento(u.getNumeroDocumento())
                .rol(u.getRol() != null ? u.getRol().getNombre() : null)
                .build();
    }

    private ConductorResponse mapToConductorResponse(Conductor c) {
        Automovil auto = c.getAutomovil();
        var usuario = c.getUsuario();
        return ConductorResponse.builder()
                .usuarioId(c.getUsuarioId())
                .nombreCompleto(usuario != null ? usuario.getNombreCompleto() : null)
                .apellidosCompletos(usuario != null ? usuario.getApellidosCompletos() : null)
                // NUEVOS: campos personales que el panel de edición admin necesita cargar
                .fechaNacimiento(usuario != null ? usuario.getFechaNacimiento() : null)
                .tipoDocumento(usuario != null ? usuario.getTipoDocumento() : null)
                .numeroDocumento(usuario != null ? usuario.getNumeroDocumento() : null)
                .email(usuario != null ? usuario.getEmail() : null)
                .telefono(usuario != null ? usuario.getTelefono() : null)
                .licencia(c.getLicencia())
                .tipoLicencia(c.getTipoLicencia())
                .disponibilidad(c.getDisponibilidad())
                .activo(c.getActivo() == null ? Boolean.TRUE : c.getActivo())
                // Datos del vehículo aplanados
                .automovilId(auto != null ? auto.getId() : null)
                .marcaVehiculo(auto != null ? auto.getMarca() : null)
                .modeloVehiculo(auto != null ? auto.getModelo() : null)
                .placaVehiculo(auto != null ? auto.getPlaca() : null)
                .capacidadMaxima(auto != null ? auto.getCapacidadMaxima() : 0)
                .categoriaVehiculo(auto != null && auto.getCategoria() != null
                        ? auto.getCategoria().getNombre() : null)
                .build();
    }

    private VehiculoResponse mapToVehiculoResponse(Automovil a) {
        // Buscar conductor asignado a este vehículo (puede ser null)
        Conductor asignado = conductorRepository.findAll().stream()
                .filter(c -> c.getAutomovil() != null
                        && c.getAutomovil().getId() != null
                        && c.getAutomovil().getId().equals(a.getId()))
                .findFirst()
                .orElse(null);

        return VehiculoResponse.builder()
                .id(a.getId())
                .marca(a.getMarca())
                .modelo(a.getModelo())
                .placa(a.getPlaca())
                .capacidadMaxima(a.getCapacidadMaxima())
                .categoriaId(a.getCategoria() != null ? a.getCategoria().getId() : null)
                .categoriaNombre(a.getCategoria() != null ? a.getCategoria().getNombre() : null)
                .conductorAsignadoId(asignado != null ? asignado.getUsuarioId() : null)
                .conductorAsignadoNombre(asignado != null && asignado.getUsuario() != null
                        ? asignado.getUsuario().getNombreCompleto() : null)
                .build();
    }

    // Mapea Viaje a ViajeResponse para los endpoints admin.
    private ViajeResponse mapToViajeResponse(Viaje v) {
        ViajeResponse.ViajeResponseBuilder builder = ViajeResponse.builder()
                .id(v.getId())
                .cantidadPasajeros(v.getCantidadPasajeros())
                .origenLat(v.getOrigenLat())
                .origenLng(v.getOrigenLng())
                .destinoLat(v.getDestinoLat())
                .destinoLng(v.getDestinoLng())
                .estadoViaje(v.getEstadoViaje())
                .precioCalculado(v.getPrecioCalculado())
                .fechaSolicitud(v.getFechaSolicitud())
                .fechaInicio(v.getFechaInicio())
                .fechaFinalizacion(v.getFechaFinalizacion());

        if (v.getCliente() != null) {
            builder.clienteId(v.getCliente().getId())
                   .clienteNombre(v.getCliente().getNombreCompleto());
        }
        if (v.getConductor() != null) {
            builder.conductorId(v.getConductor().getId())
                   .conductorNombre(v.getConductor().getNombreCompleto());
        }
        return builder.build();
    }
}

import { useEffect, useMemo, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import Table, { Row, Cell } from '../../components/ui/Table.jsx';
import Badge from '../../components/ui/Badge.jsx';
import Modal from '../../components/ui/Modal.jsx';
import Input from '../../components/ui/Input.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import {
  IconPlus,
  IconSearch,
  IconEdit,
  IconTrash,
  IconStar,
  IconCar,
  IconDrivers,
} from '../../components/icons/Icons.jsx';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

// ─── Constantes de dominio ────────────────────────────────────────────────────
const FILTERS = [
  { key: 'todos',       label: 'Todos' },
  { key: 'disponibles', label: 'Disponibles' },
  { key: 'enviaje',     label: 'En viaje' },
  { key: 'inactivos',   label: 'Inactivos' },
];
const LICENCIAS  = ['A1', 'A2', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'];
const DOCUMENTOS = ['CC', 'TI', 'PASAPORTE', 'CE', 'PERMISO_PERMANECIA'];

// ─── Helpers de UI ────────────────────────────────────────────────────────────
function Stars({ value = 0 }) {
  return (
    <span className="inline-flex gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <IconStar key={i} filled={i <= Math.round(value)} />
      ))}
    </span>
  );
}

function SectionLabel({ children }) {
  return (
    <div className="col-span-1 flex items-center gap-3 pt-2 pb-1 sm:col-span-2">
      <div className="h-px flex-1 bg-line" />
      <span className="text-[11px] font-semibold uppercase tracking-widest text-gold/70">
        {children}
      </span>
      <div className="h-px flex-1 bg-line" />
    </div>
  );
}

function SelectField({ label, value, onChange, options, placeholder, disabled }) {
  return (
    <div className="flex flex-col gap-1.5">
      <label className="label-premium">{label}</label>
      <select
        value={value}
        onChange={onChange}
        disabled={disabled}
        className="rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink outline-none focus:border-gold/60 disabled:opacity-50"
      >
        {placeholder && (
          <option value="" className="bg-surface">
            {placeholder}
          </option>
        )}
        {options.map((o) =>
          typeof o === 'string' ? (
            <option key={o} value={o} className="bg-surface">{o}</option>
          ) : (
            <option key={o.value} value={o.value} className="bg-surface">
              {o.label}
            </option>
          )
        )}
      </select>
    </div>
  );
}

// ─── Página principal ─────────────────────────────────────────────────────────
export default function ConductoresPage() {
  const toast = useToast();

  // Datos
  const [loading,    setLoading]    = useState(true);
  const [data,       setData]       = useState([]);
  const [categorias, setCategorias] = useState([]);

  // Filtros de estado
  const [filtro, setFiltro] = useState('todos');

  // Búsqueda avanzada — tres campos independientes
  const [qNombre, setQNombre] = useState('');
  const [qId,     setQId]     = useState('');
  const [qPlaca,  setQPlaca]  = useState('');

  // Modal
  const [modal, setModal] = useState(null); // null | 'crear' | conductor

  // ── Carga inicial ──────────────────────────────────────────────────────────
  const cargar = () => {
    setLoading(true);
    adminApi
      .listarConductores()
      .then((d) => setData(Array.isArray(d) ? d : (d?.content ?? [])))
      .catch(() => toast.error('Error al cargar conductores'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    cargar();
    adminApi
      .listarCategorias()
      .then((c) => setCategorias(Array.isArray(c) ? c : (c?.content ?? [])));
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // ── Filtrado reactivo ──────────────────────────────────────────────────────
  const filtrados = useMemo(() => {
    const nLow   = qNombre.toLowerCase().trim();
    const idTrim = qId.trim();
    const pLow   = qPlaca.toLowerCase().trim();

    return data.filter((c) => {
      // Filtro por estado
      if (filtro === 'disponibles' && c.disponibilidad !== true)  return false;
      if (filtro === 'inactivos'   && c.activo !== false)          return false;
      if (filtro === 'enviaje'     && !(c.disponibilidad === false && c.activo !== false)) return false;

      // Búsqueda por nombre
      if (nLow) {
        const nombre = (
          c.nombreCompleto ?? c.usuario?.nombreCompleto ?? c.nombreUsuario ?? ''
        ).toLowerCase();
        if (!nombre.includes(nLow)) return false;
      }

      // Búsqueda por ID
      if (idTrim) {
        const condId = String(c.usuarioId ?? c.id ?? '');
        if (!condId.includes(idTrim)) return false;
      }

      // Búsqueda por placa de vehículo
      if (pLow) {
        const placa = (c.placaVehiculo ?? c.automovil?.placa ?? '').toLowerCase();
        if (!placa.includes(pLow)) return false;
      }

      return true;
    });
  }, [data, filtro, qNombre, qId, qPlaca]);

  // Indica si hay algún filtro activo
  const hayFiltros = qNombre || qId || qPlaca || filtro !== 'todos';

  const limpiarFiltros = () => {
    setQNombre('');
    setQId('');
    setQPlaca('');
    setFiltro('todos');
  };

  // ── Acciones de tabla ──────────────────────────────────────────────────────
  const eliminar = async (id) => {
    try {
      await adminApi.eliminarConductor(id);
      toast.success('Conductor eliminado');
      cargar();
    } catch (e) {
      toast.error(e?.response?.data?.mensaje || e.mensaje || 'No se pudo eliminar');
    }
  };

  const toggleActivo = async (conductor) => {
    const id = conductor.usuarioId ?? conductor.id;
    try {
      if (conductor.activo === false) {
        await adminApi.habilitarConductor(id);
        toast.success('Conductor habilitado');
      } else {
        await adminApi.deshabilitarConductor(id);
        toast.success('Conductor deshabilitado');
      }
      cargar();
    } catch (e) {
      toast.error(e?.response?.data?.mensaje || e.mensaje || 'No se pudo cambiar estado');
    }
  };

  // ── Render ─────────────────────────────────────────────────────────────────
  return (
    <div>
      <PageHeader
        title="Conductores y Vehículos"
        subtitle="Gestiona la flota completa: conductores y sus vehículos asignados"
        actions={
          <Button onClick={() => setModal('crear')}>
            <IconPlus width={16} height={16} />
            Nuevo Conductor
          </Button>
        }
      />

      {/* ── Búsqueda avanzada ── */}
      <div className="mb-3 grid gap-3 sm:grid-cols-3">
        {/* Búsqueda por nombre */}
        <div className="relative">
          <IconSearch
            width={15}
            height={15}
            className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
          />
          <input
            value={qNombre}
            onChange={(e) => setQNombre(e.target.value)}
            placeholder="Buscar por nombre..."
            className="w-full rounded-lg border border-line bg-surface py-2.5 pl-10 pr-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60 transition-colors"
          />
        </div>

        {/* Búsqueda por ID */}
        <div className="relative">
          <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-[11px] font-bold text-muted">
            ID
          </span>
          <input
            value={qId}
            onChange={(e) => setQId(e.target.value)}
            placeholder="Buscar por ID..."
            className="w-full rounded-lg border border-line bg-surface py-2.5 pl-9 pr-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60 transition-colors"
          />
        </div>

        {/* Búsqueda por placa */}
        <div className="relative">
          <IconCar
            width={15}
            height={15}
            className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
          />
          <input
            value={qPlaca}
            onChange={(e) => setQPlaca(e.target.value)}
            placeholder="Buscar por placa..."
            className="w-full rounded-lg border border-line bg-surface py-2.5 pl-10 pr-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60 transition-colors"
          />
        </div>
      </div>

      {/* ── Filtros de estado + contador + limpiar ── */}
      <div className="mb-5 flex flex-wrap items-center gap-3">
        <div className="flex gap-1 rounded-lg border border-line bg-surface p-1">
          {FILTERS.map((f) => (
            <button
              key={f.key}
              onClick={() => setFiltro(f.key)}
              className={`rounded-md px-3.5 py-1.5 text-sm transition-all duration-200 ${
                filtro === f.key
                  ? 'bg-active text-gold'
                  : 'text-muted hover:text-subtle'
              }`}
            >
              {f.label}
            </button>
          ))}
        </div>

        {/* Contador de resultados */}
        <span className="text-sm text-muted">
          {filtrados.length}{' '}
          {filtrados.length === 1 ? 'resultado' : 'resultados'}
          {data.length !== filtrados.length && ` de ${data.length}`}
        </span>

        {/* Botón limpiar filtros */}
        {hayFiltros && (
          <button
            onClick={limpiarFiltros}
            className="text-[12px] text-gold/70 underline underline-offset-2 hover:text-gold transition-colors"
          >
            Limpiar filtros
          </button>
        )}
      </div>

      {/* ── Tabla ── */}
      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : (
        <Table
          head={['#', 'Conductor', 'Teléfono', 'Vehículo', 'Placa', 'Cal.', 'Estado', '']}
          empty={
            hayFiltros
              ? 'No hay conductores que coincidan con los filtros aplicados'
              : 'Aún no hay conductores registrados'
          }
        >
          {filtrados.map((c) => {
            const nombre =
              c.nombreCompleto ??
              c.usuario?.nombreCompleto ??
              c.nombreUsuario ??
              `Conductor ${c.usuarioId ?? c.id}`;
            const iniciales = nombre.slice(0, 2).toUpperCase();
            const condId    = c.usuarioId ?? c.id;
            const inactivo  = c.activo === false;

            // La API devuelve marcaVehiculo / modeloVehiculo / placaVehiculo directamente
            const vehiculoLabel =
              c.marcaVehiculo
                ? `${c.marcaVehiculo} ${c.modeloVehiculo ?? ''}`.trim()
                : c.automovil
                ? `${c.automovil.marca ?? ''} ${c.automovil.modelo ?? ''}`.trim()
                : '—';
            const placa = c.placaVehiculo ?? c.automovil?.placa ?? '—';

            return (
              <Row key={condId}>
                {/* ID */}
                <Cell className="text-[12px] text-muted font-mono">
                  #{condId}
                </Cell>
                {/* Conductor */}
                <Cell>
                  <div className="flex items-center gap-3">
                    <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full border border-gold/25 bg-gold/10 text-xs font-semibold text-gold">
                      {iniciales}
                    </div>
                    <div className="min-w-0 leading-tight">
                      <p className="truncate text-sm font-medium text-ink">{nombre}</p>
                      <p className="text-[11px] text-muted">{c.licencia ?? ''}</p>
                    </div>
                  </div>
                </Cell>
                <Cell>{c.telefono ?? c.usuario?.telefono ?? '—'}</Cell>
                <Cell>
                  <div className="flex items-center gap-1.5">
                    {vehiculoLabel !== '—' && (
                      <IconCar width={13} height={13} className="flex-shrink-0 text-muted" />
                    )}
                    <span className="text-sm">{vehiculoLabel}</span>
                  </div>
                </Cell>
                <Cell>
                  <span className="font-mono text-sm font-medium text-ink">{placa}</span>
                </Cell>
                <Cell>
                  <Stars value={c.calificacionPromedio ?? 0} />
                </Cell>
                <Cell>
                  {inactivo ? (
                    <Badge tone="red">Inactivo</Badge>
                  ) : c.disponibilidad ? (
                    <Badge tone="green">Disponible</Badge>
                  ) : (
                    <Badge tone="blue">En viaje</Badge>
                  )}
                </Cell>
                <Cell>
                  <div className="flex justify-end gap-1">
                    <button
                      onClick={() => setModal(c)}
                      className="rounded-md p-2 text-muted transition-colors hover:bg-surface hover:text-gold"
                      title="Editar conductor"
                    >
                      <IconEdit width={16} height={16} />
                    </button>
                    <button
                      onClick={() => toggleActivo(c)}
                      className={`rounded-md p-2 transition-colors hover:bg-surface ${
                        inactivo
                          ? 'text-muted hover:text-green-400'
                          : 'text-muted hover:text-amber-400'
                      }`}
                      title={inactivo ? 'Habilitar conductor' : 'Deshabilitar conductor'}
                    >
                      <IconDrivers width={16} height={16} />
                    </button>
                    <button
                      onClick={() => eliminar(condId)}
                      className="rounded-md p-2 text-muted transition-colors hover:bg-red-500/10 hover:text-red-400"
                      title="Eliminar conductor"
                    >
                      <IconTrash width={16} height={16} />
                    </button>
                  </div>
                </Cell>
              </Row>
            );
          })}
        </Table>
      )}

      <ConductorModal
        modal={modal}
        categorias={categorias}
        onClose={() => setModal(null)}
        onSaved={() => { setModal(null); cargar(); }}
      />
    </div>
  );
}

/* ─────────────────────────────────────────────────────────────────────────────
   Modal unificado Conductor + Vehículo
   — Creación: registra conductor y vehículo en una sola llamada al backend
                (RegisterConductorRequest es transaccional)
   — Edición:  actualiza campos editables del conductor
───────────────────────────────────────────────────────────────────────────── */
const FORM_INICIAL = {
  // Usuario
  nombreCompleto:     '',
  apellidosCompletos: '',
  nombreUsuario:      '',
  contrasena:         '',
  email:              '',
  telefono:           '',
  tipoDocumento:      'CC',
  numeroDocumento:    '',
  fechaNacimiento:    '',
  // Conductor
  licencia:           '',
  tipoLicencia:       'B1',
  // Vehículo
  marcaVehiculo:      '',
  modeloVehiculo:     '',
  placaVehiculo:      '',
  capacidadMaxima:    '',
  categoriaVehiculoId:'',
};

function ConductorModal({ modal, categorias, onClose, onSaved }) {
  const toast   = useToast();
  const editing = modal && modal !== 'crear';

  const [saving,  setSaving]  = useState(false);
  const [errors,  setErrors]  = useState({});
  const [form,    setForm]    = useState({});

  useEffect(() => {
    setErrors({});
    if (editing) {
      setForm({
        telefono:     modal.telefono ?? modal.usuario?.telefono ?? '',
        email:        modal.email    ?? modal.usuario?.email    ?? '',
        licencia:     modal.licencia     ?? '',
        tipoLicencia: modal.tipoLicencia ?? 'B1',
      });
    } else {
      setForm({ ...FORM_INICIAL });
    }
  }, [modal, editing]);

  if (!modal) return null;

  const set = (k) => (e) => {
    setForm((f) => ({ ...f, [k]: e.target.value }));
    // Limpiar error del campo al editar
    if (errors[k]) setErrors((e) => { const c = { ...e }; delete c[k]; return c; });
  };

  // Validación básica en cliente antes de llamar al backend
  const validar = () => {
    const errs = {};
    if (!editing) {
      if (!form.nombreCompleto?.trim())      errs.nombreCompleto    = 'Requerido';
      if (!form.apellidosCompletos?.trim())  errs.apellidosCompletos = 'Requerido';
      if (!form.nombreUsuario?.trim())       errs.nombreUsuario     = 'Requerido';
      if (!form.contrasena || form.contrasena.length < 6)
                                              errs.contrasena        = 'Mínimo 6 caracteres';
      if (!form.email?.includes('@'))        errs.email             = 'Correo inválido';
      if (!form.telefono?.trim())            errs.telefono          = 'Requerido';
      if (!form.numeroDocumento?.trim())     errs.numeroDocumento   = 'Requerido';
      if (!form.fechaNacimiento)             errs.fechaNacimiento   = 'Requerido';
      if (!form.licencia?.trim())            errs.licencia          = 'Requerido';
      if (!form.marcaVehiculo?.trim())       errs.marcaVehiculo     = 'Requerido';
      if (!form.modeloVehiculo?.trim())      errs.modeloVehiculo    = 'Requerido';
      if (!form.placaVehiculo?.trim())       errs.placaVehiculo     = 'Requerido';
      if (!form.capacidadMaxima || Number(form.capacidadMaxima) < 1)
                                              errs.capacidadMaxima   = 'Mínimo 1';
      if (!form.categoriaVehiculoId)         errs.categoriaVehiculoId = 'Requerido';
    }
    return errs;
  };

  const guardar = async () => {
    // Validación cliente
    const errs = validar();
    if (Object.keys(errs).length > 0) {
      setErrors(errs);
      toast.error('Revisa los campos marcados en rojo');
      return;
    }

    setSaving(true);
    setErrors({});
    try {
      if (editing) {
        // PUT /api/admin/conductores/{id}
        const payload = {};
        if (form.telefono)     payload.telefono     = form.telefono;
        if (form.email)        payload.email        = form.email;
        if (form.licencia)     payload.licencia     = form.licencia;
        if (form.tipoLicencia) payload.tipoLicencia = form.tipoLicencia;

        await adminApi.actualizarConductor(modal.usuarioId ?? modal.id, payload);
        toast.success('Conductor actualizado correctamente');
      } else {
        // POST /api/admin/conductores
        // El backend crea usuario + vehículo + conductor en una sola transacción
        const payload = {
          nombreCompleto:      form.nombreCompleto.trim(),
          apellidosCompletos:  form.apellidosCompletos.trim(),
          nombreUsuario:       form.nombreUsuario.trim(),
          contrasena:          form.contrasena,
          email:               form.email.trim(),
          telefono:            form.telefono.trim(),
          tipoDocumento:       form.tipoDocumento,
          numeroDocumento:     form.numeroDocumento.trim(),
          fechaNacimiento:     form.fechaNacimiento,
          licencia:            form.licencia.trim(),
          tipoLicencia:        form.tipoLicencia,
          marcaVehiculo:       form.marcaVehiculo.trim(),
          modeloVehiculo:      form.modeloVehiculo.trim(),
          placaVehiculo:       form.placaVehiculo.trim().toUpperCase(),
          capacidadMaxima:     Number(form.capacidadMaxima),
          categoriaVehiculoId: Number(form.categoriaVehiculoId),
        };

        await adminApi.crearConductor(payload);
        toast.success('Conductor y vehículo registrados y asociados correctamente');
      }
      onSaved();
    } catch (e) {
      // El backend puede devolver errores de validación por campo (MethodArgumentNotValidException)
      const serverMsg = e?.response?.data?.mensaje ?? e?.response?.data?.message ?? e.mensaje;
      const serverErrs = e?.response?.data?.errores;

      if (serverErrs && typeof serverErrs === 'object') {
        // Mapear errores de campo del backend a los campos del formulario
        setErrors(serverErrs);
        toast.error('El servidor rechazó algunos campos. Revísalos.');
      } else {
        toast.error(serverMsg || 'Error al guardar. Intenta de nuevo.');
      }
    } finally {
      setSaving(false);
    }
  };

  // Helper para mostrar error de campo
  const err = (k) =>
    errors[k] ? (
      <span className="mt-1 text-[11px] text-red-400">{errors[k]}</span>
    ) : null;

  return (
    <Modal
      open={!!modal}
      onClose={onClose}
      title={editing ? `Editar — ${modal.nombreCompleto ?? 'Conductor'}` : 'Registrar Conductor y Vehículo'}
      maxWidth="max-w-3xl"
      footer={
        <>
          <Button
            variant="ghost"
            onClick={onClose}
            disabled={saving}
            className="w-full sm:w-auto"
          >
            Cancelar
          </Button>
          <Button
            variant="gold"
            onClick={guardar}
            loading={saving}
            className="w-full sm:w-auto"
          >
            {editing ? 'Guardar cambios' : 'Registrar conductor'}
          </Button>
        </>
      }
    >
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">

        {/* ── SECCIÓN 1: Conductor ── */}
        <SectionLabel>Información del Conductor</SectionLabel>

        {!editing && (
          <>
            <div className="flex flex-col gap-1">
              <Input
                label="Nombres"
                value={form.nombreCompleto ?? ''}
                onChange={set('nombreCompleto')}
                placeholder="Ej: Carlos Andrés"
                className={errors.nombreCompleto ? 'border-red-500/60' : ''}
              />
              {err('nombreCompleto')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Apellidos"
                value={form.apellidosCompletos ?? ''}
                onChange={set('apellidosCompletos')}
                placeholder="Ej: Pérez Martínez"
                className={errors.apellidosCompletos ? 'border-red-500/60' : ''}
              />
              {err('apellidosCompletos')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Usuario"
                value={form.nombreUsuario ?? ''}
                onChange={set('nombreUsuario')}
                placeholder="Ej: cperez"
                className={errors.nombreUsuario ? 'border-red-500/60' : ''}
              />
              {err('nombreUsuario')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Contraseña"
                type="password"
                value={form.contrasena ?? ''}
                onChange={set('contrasena')}
                placeholder="Mínimo 6 caracteres"
                className={errors.contrasena ? 'border-red-500/60' : ''}
              />
              {err('contrasena')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Correo electrónico"
                type="email"
                value={form.email ?? ''}
                onChange={set('email')}
                placeholder="Ej: conductor@email.com"
                className={errors.email ? 'border-red-500/60' : ''}
              />
              {err('email')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Fecha de nacimiento"
                type="date"
                value={form.fechaNacimiento ?? ''}
                onChange={set('fechaNacimiento')}
                className={errors.fechaNacimiento ? 'border-red-500/60' : ''}
              />
              {err('fechaNacimiento')}
            </div>
            <SelectField
              label="Tipo de documento"
              value={form.tipoDocumento ?? 'CC'}
              onChange={set('tipoDocumento')}
              options={DOCUMENTOS}
            />
            <div className="flex flex-col gap-1">
              <Input
                label="N° de documento"
                value={form.numeroDocumento ?? ''}
                onChange={set('numeroDocumento')}
                placeholder="Ej: 1234567890"
                className={errors.numeroDocumento ? 'border-red-500/60' : ''}
              />
              {err('numeroDocumento')}
            </div>
          </>
        )}

        {/* Teléfono y licencia — visibles en creación y edición */}
        <div className="flex flex-col gap-1">
          <Input
            label="Teléfono"
            value={form.telefono ?? ''}
            onChange={set('telefono')}
            placeholder="Ej: 3001234567"
            className={errors.telefono ? 'border-red-500/60' : ''}
          />
          {err('telefono')}
        </div>
        <div className="flex flex-col gap-1">
          <Input
            label="N° de licencia"
            value={form.licencia ?? ''}
            onChange={set('licencia')}
            placeholder="Ej: LIC-123456"
            className={errors.licencia ? 'border-red-500/60' : ''}
          />
          {err('licencia')}
        </div>
        <SelectField
          label="Tipo de licencia"
          value={form.tipoLicencia ?? 'B1'}
          onChange={set('tipoLicencia')}
          options={LICENCIAS}
        />

        {/* ── SECCIÓN 2: Vehículo — solo en creación ── */}
        {!editing && (
          <>
            <SectionLabel>Información del Vehículo</SectionLabel>

            <div className="flex flex-col gap-1">
              <Input
                label="Marca"
                value={form.marcaVehiculo ?? ''}
                onChange={set('marcaVehiculo')}
                placeholder="Ej: Renault"
                className={errors.marcaVehiculo ? 'border-red-500/60' : ''}
              />
              {err('marcaVehiculo')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Modelo"
                value={form.modeloVehiculo ?? ''}
                onChange={set('modeloVehiculo')}
                placeholder="Ej: Logan 2022"
                className={errors.modeloVehiculo ? 'border-red-500/60' : ''}
              />
              {err('modeloVehiculo')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Placa"
                value={form.placaVehiculo ?? ''}
                onChange={(e) => {
                  set('placaVehiculo')(e);
                }}
                placeholder="Ej: ABC-123"
                className={errors.placaVehiculo ? 'border-red-500/60' : ''}
              />
              {err('placaVehiculo')}
            </div>
            <div className="flex flex-col gap-1">
              <Input
                label="Capacidad máxima"
                type="number"
                min="1"
                max="20"
                value={form.capacidadMaxima ?? ''}
                onChange={set('capacidadMaxima')}
                placeholder="Ej: 4"
                className={errors.capacidadMaxima ? 'border-red-500/60' : ''}
              />
              {err('capacidadMaxima')}
            </div>
            <div className="col-span-1 flex flex-col gap-1 sm:col-span-2">
              {categorias.length > 0 ? (
                <>
                  <SelectField
                    label="Categoría del vehículo"
                    value={form.categoriaVehiculoId ?? ''}
                    onChange={set('categoriaVehiculoId')}
                    placeholder="Selecciona una categoría…"
                    options={categorias.map((c) => ({ value: c.id, label: c.nombre }))}
                  />
                  {err('categoriaVehiculoId')}
                </>
              ) : (
                <>
                  <Input
                    label="ID de categoría del vehículo"
                    type="number"
                    value={form.categoriaVehiculoId ?? ''}
                    onChange={set('categoriaVehiculoId')}
                    placeholder="Ingresa el ID de la categoría"
                    className={errors.categoriaVehiculoId ? 'border-red-500/60' : ''}
                  />
                  {err('categoriaVehiculoId')}
                  <p className="text-[11px] text-muted">
                    No se cargaron las categorías. Ingresa el ID manualmente.
                  </p>
                </>
              )}
            </div>
          </>
        )}
      </div>
    </Modal>
  );
}

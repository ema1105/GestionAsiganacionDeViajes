import { useEffect, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Input from '../../components/ui/Input.jsx';
import Button from '../../components/ui/Button.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { useAuth } from '../../hooks/useAuth.js';
import { ROLES, ROLE_LABEL } from '../../constants/roles.js';
import { clienteApi } from '../../api/cliente.api.js';
import { conductorApi } from '../../api/conductor.api.js';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

// Servicio de perfil según el rol del usuario autenticado.
// Todos los roles tienen acceso a edición; el payload varía según permisos del backend.
function buildService(rol) {
  if (rol === ROLES.ADMIN)     return adminApi;
  if (rol === ROLES.CLIENTE)   return clienteApi;
  if (rol === ROLES.CONDUCTOR) return conductorApi;
  // RECEPCIONISTA sin endpoint propio → usa clienteApi como fallback
  return clienteApi;
}

// Campos editables por rol
function camposEditables(rol) {
  return {
    email:    true,
    telefono: true,
    contrasena: true,
    // Nombre y apellidos: solo conductores pueden cambiarlos vía ActualizarConductorRequest
    nombreCompleto:     rol === ROLES.CONDUCTOR,
    apellidosCompletos: rol === ROLES.CONDUCTOR,
  };
}

export default function PerfilPage() {
  const { user } = useAuth();
  const toast    = useToast();
  const svc      = buildService(user?.rol);
  const editable = camposEditables(user?.rol);

  const [form, setForm]     = useState({
    nombreCompleto:     '',
    apellidosCompletos: '',
    email:              '',
    telefono:           '',
    contrasena:         '',
  });
  const [original, setOriginal] = useState({});
  const [loading,  setLoading]  = useState(true);
  const [saving,   setSaving]   = useState(false);
  const [editMode, setEditMode] = useState(false);
  const [vehiculo, setVehiculo] = useState(null); // solo lectura (conductor)

  useEffect(() => {
    if (!svc?.obtenerPerfil) {
      setLoading(false);
      return;
    }
    svc
      .obtenerPerfil()
      .then((p) => {
        if (!p) { setLoading(false); return; }
        const datos = {
          nombreCompleto:     p.nombreCompleto     ?? '',
          apellidosCompletos: p.apellidosCompletos ?? '',
          email:              p.email              ?? '',
          telefono:           p.telefono           ?? '',
          contrasena:         '',
        };
        setForm(datos);
        setOriginal(datos);
        // El conductor visualiza (solo lectura) su vehículo asignado.
        if (user?.rol === ROLES.CONDUCTOR && p.placaVehiculo) {
          setVehiculo({
            placa:     p.placaVehiculo,
            modelo:    p.modeloVehiculo,
            marca:     p.marcaVehiculo,
            capacidad: p.capacidadMaxima,
            tipo:      p.categoriaVehiculo,
          });
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [svc]); // eslint-disable-line react-hooks/exhaustive-deps

  const set = (k) => (e) => setForm((f) => ({ ...f, [k]: e.target.value }));

  const cancelar = () => {
    setForm({ ...original, contrasena: '' });
    setEditMode(false);
  };

  const guardar = async () => {
    if (!svc?.actualizarPerfil) return;
    setSaving(true);
    try {
      const payload = {};
      if (editable.email    && form.email !== original.email)       payload.email    = form.email;
      if (editable.telefono && form.telefono !== original.telefono) payload.telefono = form.telefono;
      if (form.contrasena)                                           payload.contrasena = form.contrasena;
      if (editable.nombreCompleto    && form.nombreCompleto    !== original.nombreCompleto)
        payload.nombreCompleto    = form.nombreCompleto;
      if (editable.apellidosCompletos && form.apellidosCompletos !== original.apellidosCompletos)
        payload.apellidosCompletos = form.apellidosCompletos;

      if (Object.keys(payload).length === 0) {
        toast.info('No hay cambios para guardar');
        setEditMode(false);
        return;
      }

      await svc.actualizarPerfil(payload);
      setOriginal({ ...form, contrasena: '' });
      setForm((f) => ({ ...f, contrasena: '' }));
      toast.success('Cambios guardados correctamente');
      setEditMode(false);
    } catch (e) {
      toast.error(
        e?.response?.data?.mensaje || e.mensaje || 'No se pudo guardar'
      );
    } finally {
      setSaving(false);
    }
  };

  const iniciales = (user?.nombreUsuario ?? '?').slice(0, 2).toUpperCase();

  if (loading) {
    return (
      <div className="flex h-64 items-center justify-center">
        <Spinner size="h-8 w-8" />
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Mi Perfil"
        subtitle="Gestiona tu información personal y credenciales de acceso"
        actions={
          !editMode ? (
            <Button onClick={() => setEditMode(true)}>
              Editar perfil
            </Button>
          ) : null
        }
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">

        {/* ── Tarjeta de identidad ── */}
        <Card className="flex flex-col items-center p-8 text-center">
          <div className="relative">
            <div className="flex h-24 w-24 items-center justify-center rounded-full border-2 border-gold/40 bg-gold/10 text-2xl font-semibold text-gold shadow-lg">
              {iniciales}
            </div>
            {editMode && (
              <span className="absolute -bottom-1 -right-1 rounded-full bg-gold px-1.5 py-0.5 text-[9px] font-bold text-black uppercase">
                editando
              </span>
            )}
          </div>
          <p className="mt-4 font-serif text-2xl text-ink">
            {form.nombreCompleto || user?.nombreUsuario}
          </p>
          <p className="text-sm text-muted">{form.apellidosCompletos}</p>
          <span className="mt-3 inline-flex rounded-full border border-gold/25 bg-gold/10 px-3 py-1 text-[11px] font-medium text-gold">
            {ROLE_LABEL[user?.rol] ?? 'Usuario'}
          </span>

          {/* Datos fijos */}
          <div className="mt-6 w-full space-y-3 text-left">
            <div className="rounded-lg bg-surface/60 px-4 py-3">
              <p className="text-[10px] uppercase tracking-wider text-muted">Usuario</p>
              <p className="mt-0.5 text-sm font-medium text-ink">{user?.nombreUsuario}</p>
            </div>
            <div className="rounded-lg bg-surface/60 px-4 py-3">
              <p className="text-[10px] uppercase tracking-wider text-muted">Rol</p>
              <p className="mt-0.5 text-sm font-medium text-ink">
                {ROLE_LABEL[user?.rol] ?? user?.rol}
              </p>
            </div>
          </div>
        </Card>

        {/* ── Formulario de edición ── */}
        <Card className="p-8 lg:col-span-2">
          <h3 className="mb-5 font-serif text-lg text-ink">
            {editMode ? 'Editar información' : 'Información personal'}
          </h3>

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input
              label="Nombres"
              value={form.nombreCompleto}
              onChange={set('nombreCompleto')}
              disabled={!editMode || !editable.nombreCompleto}
              placeholder={!editable.nombreCompleto ? 'No editable en este rol' : ''}
            />
            <Input
              label="Apellidos"
              value={form.apellidosCompletos}
              onChange={set('apellidosCompletos')}
              disabled={!editMode || !editable.apellidosCompletos}
              placeholder={!editable.apellidosCompletos ? 'No editable en este rol' : ''}
            />
            <Input
              label="Correo electrónico"
              type="email"
              value={form.email}
              onChange={set('email')}
              disabled={!editMode || !editable.email}
            />
            <Input
              label="Teléfono"
              value={form.telefono}
              onChange={set('telefono')}
              disabled={!editMode || !editable.telefono}
            />
            <div className="sm:col-span-2">
              <Input
                label="Nueva contraseña"
                type="password"
                placeholder={editMode ? 'Dejar vacío para no cambiar' : '••••••••'}
                value={form.contrasena}
                onChange={set('contrasena')}
                disabled={!editMode}
              />
            </div>
          </div>

          {editMode && (
            <div className="mt-6 flex justify-end gap-3">
              <Button variant="ghost" onClick={cancelar} disabled={saving}>
                Cancelar
              </Button>
              <Button onClick={guardar} loading={saving}>
                Guardar cambios
              </Button>
            </div>
          )}

          {!editMode && (
            <p className="mt-6 text-sm text-muted">
              Los campos de solo lectura muestran tu información actual.
              Usa el botón <span className="text-gold">Editar perfil</span> para modificarla.
            </p>
          )}
        </Card>
      </div>

      {/* ── Vehículo asignado — solo lectura (conductor) ── */}
      {vehiculo && (
        <Card className="mt-6 p-8">
          <div className="mb-5 flex items-center justify-between">
            <div>
              <h3 className="font-serif text-lg text-ink">Vehículo asignado</h3>
              <p className="text-sm text-muted">
                Información gestionada por administración — solo lectura
              </p>
            </div>
            <span className="inline-flex items-center gap-1.5 rounded-full border border-line bg-surface/60 px-3 py-1 text-[11px] font-medium text-muted">
              <span className="h-1.5 w-1.5 rounded-full bg-muted" />
              No editable
            </span>
          </div>

          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
            <DatoVehiculo etiqueta="Placa"     valor={vehiculo.placa} highlight />
            <DatoVehiculo etiqueta="Marca"     valor={vehiculo.marca} />
            <DatoVehiculo etiqueta="Modelo"    valor={vehiculo.modelo} />
            <DatoVehiculo
              etiqueta="Capacidad"
              valor={vehiculo.capacidad ? `${vehiculo.capacidad} pasajeros` : null}
            />
            <DatoVehiculo etiqueta="Tipo"      valor={vehiculo.tipo} />
          </div>
        </Card>
      )}
    </div>
  );
}

// Celda de dato del vehículo con etiqueta superior (solo lectura).
function DatoVehiculo({ etiqueta, valor, highlight = false }) {
  return (
    <div className="rounded-lg bg-surface/60 px-4 py-3">
      <p className="text-[10px] uppercase tracking-wider text-muted">{etiqueta}</p>
      <p
        className={`mt-1 text-sm font-medium ${
          highlight ? 'font-mono text-gold' : 'text-ink'
        }`}
      >
        {valor ?? '—'}
      </p>
    </div>
  );
}

import { useEffect, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Input from '../../components/ui/Input.jsx';
import Button from '../../components/ui/Button.jsx';
import { useAuth } from '../../hooks/useAuth.js';
import { ROLES, ROLE_LABEL } from '../../constants/roles.js';
import { clienteApi } from '../../api/cliente.api.js';
import { conductorApi } from '../../api/conductor.api.js';
import { useToast } from '../../context/ToastContext.jsx';

// Selecciona el servicio de perfil según el rol. ADMIN no tiene endpoint
// dedicado en el backend: se muestra el perfil en modo solo-lectura.
function perfilService(rol) {
  if (rol === ROLES.CLIENTE) return clienteApi;
  if (rol === ROLES.CONDUCTOR) return conductorApi;
  return null;
}

export default function PerfilPage() {
  const { user } = useAuth();
  const toast = useToast();
  const svc = perfilService(user?.rol);

  const [form, setForm] = useState({
    nombreCompleto: '',
    apellidosCompletos: '',
    email: '',
    telefono: '',
    contrasena: '',
  });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!svc) return;
    svc
      .obtenerPerfil()
      .then((p) =>
        setForm((f) => ({
          ...f,
          nombreCompleto: p.nombreCompleto ?? '',
          apellidosCompletos: p.apellidosCompletos ?? '',
          email: p.email ?? '',
          telefono: p.telefono ?? '',
        }))
      )
      .catch(() => {});
  }, [svc]);

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const guardar = async () => {
    if (!svc) {
      toast.info('El perfil de administrador es de solo lectura');
      return;
    }
    setSaving(true);
    try {
      const payload = {
        email: form.email,
        telefono: form.telefono,
      };
      if (form.contrasena) payload.contrasena = form.contrasena;
      await svc.actualizarPerfil(payload);
      toast.success('Cambios guardados');
      setForm({ ...form, contrasena: '' });
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo guardar');
    } finally {
      setSaving(false);
    }
  };

  const iniciales = (user?.nombreUsuario ?? '?').slice(0, 2).toUpperCase();

  return (
    <div>
      <PageHeader
        title="Mi Perfil"
        subtitle="Gestiona tu información personal"
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Card de identidad */}
        <Card className="flex flex-col items-center p-8 text-center">
          <div className="flex h-24 w-24 items-center justify-center rounded-full border border-gold/30 bg-gold/10 text-2xl font-semibold text-gold">
            {iniciales}
          </div>
          <p className="mt-4 font-serif text-2xl text-ink">
            {user?.nombreUsuario}
          </p>
          <span className="mt-2 inline-flex rounded-full border border-gold/25 bg-gold/10 px-3 py-1 text-[11px] font-medium text-gold">
            {ROLE_LABEL[user?.rol] ?? 'Usuario'}
          </span>
        </Card>

        {/* Formulario */}
        <Card className="p-8 lg:col-span-2">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input
              label="Nombres"
              value={form.nombreCompleto}
              onChange={set('nombreCompleto')}
              disabled={!svc}
            />
            <Input
              label="Apellidos"
              value={form.apellidosCompletos}
              onChange={set('apellidosCompletos')}
              disabled={!svc}
            />
            <Input
              label="Correo"
              type="email"
              value={form.email}
              onChange={set('email')}
              disabled={!svc}
            />
            <Input
              label="Teléfono"
              value={form.telefono}
              onChange={set('telefono')}
              disabled={!svc}
            />
            <div className="sm:col-span-2">
              <Input
                label="Nueva contraseña"
                type="password"
                placeholder="Dejar vacío para no cambiar"
                value={form.contrasena}
                onChange={set('contrasena')}
                disabled={!svc}
              />
            </div>
          </div>
          <div className="mt-6 flex justify-end">
            <Button onClick={guardar} loading={saving} disabled={!svc}>
              Guardar Cambios
            </Button>
          </div>
        </Card>
      </div>
    </div>
  );
}

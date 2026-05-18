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
} from '../../components/icons/Icons.jsx';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const FILTERS = [
  { key: 'todos', label: 'Todos' },
  { key: 'disponibles', label: 'Disponibles' },
  { key: 'enviaje', label: 'En viaje' },
  { key: 'inactivos', label: 'Inactivos' },
];

function Stars({ value = 0 }) {
  return (
    <span className="inline-flex gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <IconStar key={i} filled={i <= Math.round(value)} />
      ))}
    </span>
  );
}

export default function ConductoresPage() {
  const toast = useToast();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState([]);
  const [filtro, setFiltro] = useState('todos');
  const [q, setQ] = useState('');
  const [modal, setModal] = useState(null); // null | 'crear' | conductor

  const cargar = () => {
    setLoading(true);
    adminApi
      .listarConductores()
      .then((d) => setData(Array.isArray(d) ? d : d?.content ?? []))
      .catch(() => toast.error('Error al cargar conductores'))
      .finally(() => setLoading(false));
  };

  useEffect(cargar, []); // eslint-disable-line react-hooks/exhaustive-deps

  const filtrados = useMemo(() => {
    return data.filter((c) => {
      const nombre = (
        c.nombreCompleto ??
        c.usuario?.nombreCompleto ??
        c.nombreUsuario ??
        ''
      ).toLowerCase();
      if (q && !nombre.includes(q.toLowerCase())) return false;
      if (filtro === 'disponibles') return c.disponibilidad === true;
      if (filtro === 'inactivos') return c.activo === false;
      if (filtro === 'enviaje') return c.disponibilidad === false && c.activo !== false;
      return true;
    });
  }, [data, q, filtro]);

  const eliminar = async (id) => {
    try {
      await adminApi.eliminarConductor(id);
      toast.success('Conductor eliminado');
      cargar();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo eliminar');
    }
  };

  return (
    <div>
      <PageHeader
        title="Gestión de Conductores"
        subtitle="Administra la flota de conductores de la plataforma"
        actions={
          <Button onClick={() => setModal('crear')}>
            <IconPlus width={16} height={16} />
            Nuevo Conductor
          </Button>
        }
      />

      <div className="mb-5 flex flex-wrap items-center gap-3">
        <div className="relative flex-1 min-w-[220px]">
          <IconSearch
            width={16}
            height={16}
            className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
          />
          <input
            value={q}
            onChange={(e) => setQ(e.target.value)}
            placeholder="Buscar por nombre..."
            className="w-full rounded-lg border border-line bg-surface py-2.5 pl-10 pr-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60"
          />
        </div>
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
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : (
        <Table
          head={['Conductor', 'Teléfono', 'Vehículo', 'Placa', 'Calificación', 'Estado', '']}
          empty="No hay conductores que coincidan"
        >
          {filtrados.length > 0 &&
            filtrados.map((c) => {
              const nombre =
                c.nombreCompleto ??
                c.usuario?.nombreCompleto ??
                c.nombreUsuario ??
                `Conductor ${c.usuarioId ?? c.id}`;
              const iniciales = nombre.slice(0, 2).toUpperCase();
              const inactivo = c.activo === false;
              return (
                <Row key={c.usuarioId ?? c.id}>
                  <Cell>
                    <div className="flex items-center gap-3">
                      <div className="flex h-9 w-9 items-center justify-center rounded-full border border-gold/25 bg-gold/10 text-xs font-semibold text-gold">
                        {iniciales}
                      </div>
                      <span className="text-ink">{nombre}</span>
                    </div>
                  </Cell>
                  <Cell>{c.telefono ?? c.usuario?.telefono ?? '—'}</Cell>
                  <Cell>
                    {c.automovil
                      ? `${c.automovil.marca} ${c.automovil.modelo}`
                      : '—'}
                  </Cell>
                  <Cell className="text-muted">
                    {c.automovil?.placa ?? '—'}
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
                        title="Editar"
                      >
                        <IconEdit width={16} height={16} />
                      </button>
                      <button
                        onClick={() => eliminar(c.usuarioId ?? c.id)}
                        className="rounded-md p-2 text-muted transition-colors hover:bg-red-500/10 hover:text-red-400"
                        title="Eliminar"
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
        onClose={() => setModal(null)}
        onSaved={() => {
          setModal(null);
          cargar();
        }}
      />
    </div>
  );
}

function ConductorModal({ modal, onClose, onSaved }) {
  const toast = useToast();
  const editing = modal && modal !== 'crear';
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({});

  useEffect(() => {
    if (editing) {
      setForm({
        licencia: modal.licencia ?? '',
        tipoLicencia: modal.tipoLicencia ?? 'B1',
        telefono: modal.telefono ?? modal.usuario?.telefono ?? '',
      });
    } else {
      setForm({
        nombreCompleto: '',
        apellidosCompletos: '',
        nombreUsuario: '',
        contrasena: '',
        email: '',
        telefono: '',
        numeroDocumento: '',
        tipoDocumento: 'CC',
        fechaNacimiento: '',
        licencia: '',
        tipoLicencia: 'B1',
      });
    }
  }, [modal, editing]);

  if (!modal) return null;

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const guardar = async () => {
    setSaving(true);
    try {
      if (editing) {
        await adminApi.actualizarConductor(
          modal.usuarioId ?? modal.id,
          form
        );
        toast.success('Conductor actualizado');
      } else {
        await adminApi.crearConductor(form);
        toast.success('Conductor creado');
      }
      onSaved();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo guardar');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={!!modal}
      onClose={onClose}
      title={editing ? 'Editar Conductor' : 'Nuevo Conductor'}
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancelar
          </Button>
          <Button onClick={guardar} loading={saving}>
            Guardar
          </Button>
        </>
      }
    >
      <div className="grid grid-cols-2 gap-4">
        {!editing && (
          <>
            <Input label="Nombres" value={form.nombreCompleto ?? ''} onChange={set('nombreCompleto')} />
            <Input label="Apellidos" value={form.apellidosCompletos ?? ''} onChange={set('apellidosCompletos')} />
            <Input label="Usuario" value={form.nombreUsuario ?? ''} onChange={set('nombreUsuario')} />
            <Input label="Contraseña" type="password" value={form.contrasena ?? ''} onChange={set('contrasena')} />
            <Input label="Correo" value={form.email ?? ''} onChange={set('email')} />
            <Input label="N° Documento" value={form.numeroDocumento ?? ''} onChange={set('numeroDocumento')} />
          </>
        )}
        <Input label="Teléfono" value={form.telefono ?? ''} onChange={set('telefono')} />
        <Input label="Licencia" value={form.licencia ?? ''} onChange={set('licencia')} />
        <div className="flex flex-col gap-1.5">
          <label className="label-premium">Tipo licencia</label>
          <select
            value={form.tipoLicencia ?? 'B1'}
            onChange={set('tipoLicencia')}
            className="rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink outline-none focus:border-gold/60"
          >
            {['A1', 'A2', 'B1', 'B2', 'B3', 'C1', 'C2', 'C3'].map((t) => (
              <option key={t} value={t} className="bg-surface">
                {t}
              </option>
            ))}
          </select>
        </div>
      </div>
    </Modal>
  );
}

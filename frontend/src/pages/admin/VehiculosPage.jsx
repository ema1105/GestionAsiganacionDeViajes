import { useEffect, useMemo, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import Table, { Row, Cell } from '../../components/ui/Table.jsx';
import Modal from '../../components/ui/Modal.jsx';
import Input from '../../components/ui/Input.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import {
  IconPlus,
  IconSearch,
  IconEdit,
  IconTrash,
  IconDrivers,
} from '../../components/icons/Icons.jsx';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

export default function VehiculosPage() {
  const toast = useToast();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState([]);
  const [categorias, setCategorias] = useState([]);
  const [q, setQ] = useState('');
  const [modal, setModal] = useState(null); // null | 'crear' | vehiculo
  const [asignar, setAsignar] = useState(null); // vehiculo a asignar

  const cargar = () => {
    setLoading(true);
    adminApi
      .listarVehiculos()
      .then((d) => setData(Array.isArray(d) ? d : (d?.content ?? [])))
      .catch(() => toast.error('Error al cargar vehículos'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    cargar();
    adminApi
      .listarCategorias()
      .then((c) => setCategorias(Array.isArray(c) ? c : (c?.content ?? [])));
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  const filtrados = useMemo(
    () =>
      data.filter((v) => {
        if (!q) return true;
        const txt =
          `${v.marca ?? ''} ${v.modelo ?? ''} ${v.placa ?? ''}`.toLowerCase();
        return txt.includes(q.toLowerCase());
      }),
    [data, q]
  );

  const eliminar = async (id) => {
    try {
      await adminApi.eliminarVehiculo(id);
      toast.success('Vehículo eliminado');
      cargar();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo eliminar');
    }
  };

  return (
    <div>
      <PageHeader
        title="Gestión de Vehículos"
        subtitle="Flota registrada en la plataforma GAV"
        actions={
          <Button onClick={() => setModal('crear')}>
            <IconPlus width={16} height={16} />
            Nuevo Vehículo
          </Button>
        }
      />

      <div className="relative mb-5 max-w-md">
        <IconSearch
          width={16}
          height={16}
          className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
        />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Buscar por marca, modelo o placa..."
          className="w-full rounded-lg border border-line bg-surface py-2.5 pl-10 pr-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60"
        />
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : (
        <Table
          head={['Marca', 'Modelo', 'Placa', 'Capacidad', 'Categoría', '']}
          empty="No hay vehículos registrados"
        >
          {filtrados.length > 0 &&
            filtrados.map((v) => (
              <Row key={v.id}>
                <Cell className="text-ink">{v.marca ?? '—'}</Cell>
                <Cell>{v.modelo ?? '—'}</Cell>
                <Cell className="font-medium text-ink">{v.placa ?? '—'}</Cell>
                <Cell>{v.capacidadMaxima ?? v.capacidad ?? '—'}</Cell>
                <Cell className="text-muted">
                  {v.categoria?.nombre ?? v.categoriaNombre ?? '—'}
                </Cell>
                <Cell>
                  <div className="flex justify-end gap-1">
                    <button
                      onClick={() => setAsignar(v)}
                      className="rounded-md p-2 text-muted transition-colors hover:bg-surface hover:text-gold"
                      title="Asignar a conductor"
                    >
                      <IconDrivers width={16} height={16} />
                    </button>
                    <button
                      onClick={() => setModal(v)}
                      className="rounded-md p-2 text-muted transition-colors hover:bg-surface hover:text-gold"
                      title="Editar"
                    >
                      <IconEdit width={16} height={16} />
                    </button>
                    <button
                      onClick={() => eliminar(v.id)}
                      className="rounded-md p-2 text-muted transition-colors hover:bg-red-500/10 hover:text-red-400"
                      title="Eliminar"
                    >
                      <IconTrash width={16} height={16} />
                    </button>
                  </div>
                </Cell>
              </Row>
            ))}
        </Table>
      )}

      <VehiculoModal
        modal={modal}
        categorias={categorias}
        onClose={() => setModal(null)}
        onSaved={() => {
          setModal(null);
          cargar();
        }}
      />

      <AsignarModal
        vehiculo={asignar}
        onClose={() => setAsignar(null)}
        onDone={() => {
          setAsignar(null);
          cargar();
        }}
      />
    </div>
  );
}

function VehiculoModal({ modal, categorias, onClose, onSaved }) {
  const toast = useToast();
  const editing = modal && modal !== 'crear';
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({});

  useEffect(() => {
    if (editing) {
      setForm({
        marca: modal.marca ?? '',
        modelo: modal.modelo ?? '',
        placa: modal.placa ?? '',
        capacidadMaxima: modal.capacidadMaxima ?? modal.capacidad ?? '',
        categoriaId:
          modal.categoria?.id ?? modal.categoriaId ?? '',
      });
    } else {
      setForm({
        marca: '',
        modelo: '',
        placa: '',
        capacidadMaxima: '',
        categoriaId: '',
      });
    }
  }, [modal, editing]);

  if (!modal) return null;

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  const guardar = async () => {
    setSaving(true);
    try {
      const payload = {
        ...form,
        capacidadMaxima: Number(form.capacidadMaxima),
        categoriaId: form.categoriaId ? Number(form.categoriaId) : undefined,
      };
      if (editing) {
        await adminApi.actualizarVehiculo(modal.id, payload);
        toast.success('Vehículo actualizado');
      } else {
        await adminApi.crearVehiculo(payload);
        toast.success('Vehículo creado');
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
      title={editing ? 'Editar Vehículo' : 'Nuevo Vehículo'}
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
        <Input label="Marca" value={form.marca ?? ''} onChange={set('marca')} />
        <Input
          label="Modelo"
          value={form.modelo ?? ''}
          onChange={set('modelo')}
        />
        <Input label="Placa" value={form.placa ?? ''} onChange={set('placa')} />
        <Input
          label="Capacidad máxima"
          type="number"
          min="1"
          value={form.capacidadMaxima ?? ''}
          onChange={set('capacidadMaxima')}
        />
        <div className="col-span-2 flex flex-col gap-1.5">
          <label className="label-premium">Categoría</label>
          {categorias.length > 0 ? (
            <select
              value={form.categoriaId ?? ''}
              onChange={set('categoriaId')}
              className="rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink outline-none focus:border-gold/60"
            >
              <option value="" className="bg-surface">
                Selecciona…
              </option>
              {categorias.map((c) => (
                <option key={c.id} value={c.id} className="bg-surface">
                  {c.nombre}
                </option>
              ))}
            </select>
          ) : (
            <input
              type="number"
              placeholder="ID de categoría"
              value={form.categoriaId ?? ''}
              onChange={set('categoriaId')}
              className="rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60"
            />
          )}
        </div>
      </div>
    </Modal>
  );
}

function AsignarModal({ vehiculo, onClose, onDone }) {
  const toast = useToast();
  const [conductores, setConductores] = useState([]);
  const [sel, setSel] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!vehiculo) return;
    adminApi
      .listarConductores()
      .then((d) =>
        setConductores(Array.isArray(d) ? d : (d?.content ?? []))
      )
      .catch(() => {});
    setSel('');
  }, [vehiculo]);

  if (!vehiculo) return null;

  const asignar = async () => {
    if (!sel) return;
    setSaving(true);
    try {
      await adminApi.asociarVehiculo(sel, vehiculo.id);
      toast.success('Vehículo asignado al conductor');
      onDone();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo asignar');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={!!vehiculo}
      onClose={onClose}
      title={`Asignar ${vehiculo.marca ?? 'vehículo'} ${vehiculo.placa ?? ''}`}
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancelar
          </Button>
          <Button onClick={asignar} loading={saving} disabled={!sel}>
            Asignar
          </Button>
        </>
      }
    >
      <div className="flex flex-col gap-1.5">
        <label className="label-premium">Conductor</label>
        <select
          value={sel}
          onChange={(e) => setSel(e.target.value)}
          className="rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink outline-none focus:border-gold/60"
        >
          <option value="" className="bg-surface">
            Selecciona un conductor…
          </option>
          {conductores.map((c) => {
            const id = c.usuarioId ?? c.id;
            const nombre =
              c.nombreCompleto ??
              c.usuario?.nombreCompleto ??
              c.nombreUsuario ??
              `Conductor ${id}`;
            return (
              <option key={id} value={id} className="bg-surface">
                {nombre}
              </option>
            );
          })}
        </select>
      </div>
    </Modal>
  );
}

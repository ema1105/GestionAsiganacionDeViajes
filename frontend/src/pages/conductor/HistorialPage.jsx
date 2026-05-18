import { useEffect, useState, useCallback } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import Table, { Row, Cell } from '../../components/ui/Table.jsx';
import Badge, { estadoViajeTone } from '../../components/ui/Badge.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { conductorApi } from '../../api/conductor.api.js';
import { useToast } from '../../context/ToastContext.jsx';
import { useRoleGate } from '../../hooks/useRoleGate.js';
import { ROLES } from '../../constants/roles.js';

const ESTADOS = [
  'ACEPTADO',
  'EN_CAMINO',
  'EN_CURSO',
  'FINALIZADO',
  'CANCELADO',
];

const fmtMoney = (n) =>
  new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n || 0);

const fmtFecha = (f) => {
  if (!f) return '—';
  try {
    return new Date(f).toLocaleString('es-CO', {
      day: '2-digit',
      month: 'short',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return f;
  }
};

const SIZE = 10;

export default function HistorialPage() {
  const toast = useToast();
  const { authorized } = useRoleGate(ROLES.CONDUCTOR);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [data, setData] = useState({
    content: [],
    totalElements: 0,
    totalPages: 1,
  });
  const [filtros, setFiltros] = useState({ estado: '', desde: '', hasta: '' });

  const cargar = useCallback(
    (pg, f) => {
      setLoading(true);
      const params = { page: pg, size: SIZE };
      if (f.estado) params.estado = f.estado;
      if (f.desde) params.desde = f.desde;
      if (f.hasta) params.hasta = f.hasta;
      conductorApi
        .historialViajes(params)
        .then((d) => {
          if (Array.isArray(d)) {
            setData({ content: d, totalElements: d.length, totalPages: 1 });
          } else {
            setData({
              content: d?.content ?? [],
              totalElements: d?.totalElements ?? 0,
              totalPages: d?.totalPages ?? 1,
            });
          }
        })
        .catch(() => toast.error('Error al cargar el historial'))
        .finally(() => setLoading(false));
    },
    [toast]
  );

  useEffect(() => {
    if (!authorized) return;
    cargar(page, filtros);
  }, [authorized, page, cargar]); // eslint-disable-line react-hooks/exhaustive-deps

  const aplicar = () => {
    setPage(0);
    cargar(0, filtros);
  };
  const limpiar = () => {
    const vacio = { estado: '', desde: '', hasta: '' };
    setFiltros(vacio);
    setPage(0);
    cargar(0, vacio);
  };

  return (
    <div>
      <PageHeader
        title="Historial de Viajes"
        subtitle="Todos tus viajes realizados en la plataforma"
      />

      <div className="mb-5 flex flex-wrap items-end gap-3">
        <div className="flex flex-col gap-1.5">
          <label className="label-premium">Estado</label>
          <select
            value={filtros.estado}
            onChange={(e) =>
              setFiltros({ ...filtros, estado: e.target.value })
            }
            className="rounded-lg border border-line bg-surface px-3.5 py-2.5 text-sm text-ink outline-none focus:border-gold/60"
          >
            <option value="" className="bg-surface">
              Todos
            </option>
            {ESTADOS.map((s) => (
              <option key={s} value={s} className="bg-surface">
                {s}
              </option>
            ))}
          </select>
        </div>
        <div className="flex flex-col gap-1.5">
          <label className="label-premium">Desde</label>
          <input
            type="date"
            value={filtros.desde}
            onChange={(e) =>
              setFiltros({ ...filtros, desde: e.target.value })
            }
            className="rounded-lg border border-line bg-surface px-3.5 py-2.5 text-sm text-ink outline-none focus:border-gold/60"
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <label className="label-premium">Hasta</label>
          <input
            type="date"
            value={filtros.hasta}
            onChange={(e) =>
              setFiltros({ ...filtros, hasta: e.target.value })
            }
            className="rounded-lg border border-line bg-surface px-3.5 py-2.5 text-sm text-ink outline-none focus:border-gold/60"
          />
        </div>
        <Button onClick={aplicar}>Aplicar</Button>
        <Button variant="ghost" onClick={limpiar}>
          Limpiar
        </Button>
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : (
        <>
          <Table
            head={['ID', 'Cliente', 'Precio', 'Fecha', 'Estado']}
            empty="No tienes viajes que coincidan"
          >
            {data.content.length > 0 &&
              data.content.map((v) => (
                <Row key={v.id}>
                  <Cell className="text-muted">#{v.id}</Cell>
                  <Cell className="text-ink">
                    {v.clienteNombre ?? `Cliente ${v.clienteId ?? '—'}`}
                  </Cell>
                  <Cell className="text-ink">
                    {fmtMoney(v.precioCalculado ?? v.precio)}
                  </Cell>
                  <Cell className="text-muted">
                    {fmtFecha(v.fechaSolicitud ?? v.fechaInicio)}
                  </Cell>
                  <Cell>
                    <Badge tone={estadoViajeTone(v.estadoViaje)}>
                      {v.estadoViaje}
                    </Badge>
                  </Cell>
                </Row>
              ))}
          </Table>

          <div className="mt-4 flex items-center justify-between">
            <p className="text-sm text-muted">
              {data.totalElements} viajes · página {page + 1} de{' '}
              {data.totalPages || 1}
            </p>
            <div className="flex gap-2">
              <Button
                variant="outline"
                disabled={page === 0}
                onClick={() => setPage((p) => Math.max(0, p - 1))}
              >
                Anterior
              </Button>
              <Button
                variant="outline"
                disabled={page + 1 >= (data.totalPages || 1)}
                onClick={() => setPage((p) => p + 1)}
              >
                Siguiente
              </Button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}

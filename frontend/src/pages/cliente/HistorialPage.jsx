import { useEffect, useState, useCallback } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Button from '../../components/ui/Button.jsx';
import Table, { Row, Cell } from '../../components/ui/Table.jsx';
import Badge, { estadoViajeTone } from '../../components/ui/Badge.jsx';
import Modal from '../../components/ui/Modal.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { IconStar } from '../../components/icons/Icons.jsx';
import { clienteApi } from '../../api/cliente.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const CANCELABLES = ['SOLICITADO', 'BUSCANDO_CONDUCTOR', 'ACEPTADO'];

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
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(0);
  const [data, setData] = useState({
    content: [],
    totalElements: 0,
    totalPages: 1,
  });
  const [calificar, setCalificar] = useState(null);

  const cargar = useCallback(
    (pg) => {
      setLoading(true);
      clienteApi
        .listarViajes({ page: pg, size: SIZE })
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
        .catch(() => toast.error('Error al cargar tu historial'))
        .finally(() => setLoading(false));
    },
    [toast]
  );

  useEffect(() => {
    cargar(page);
  }, [page, cargar]);

  const cancelar = async (id) => {
    try {
      await clienteApi.cancelarViaje(id, 'Cancelado por el cliente');
      toast.success('Viaje cancelado');
      cargar(page);
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo cancelar');
    }
  };

  return (
    <div>
      <PageHeader
        title="Mis Viajes"
        subtitle="Historial completo de tus viajes en GAV"
      />

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : (
        <>
          <Table
            head={['ID', 'Conductor', 'Precio', 'Fecha', 'Estado', '']}
            empty="Todavía no has realizado viajes"
          >
            {data.content.length > 0 &&
              data.content.map((v) => (
                <Row key={v.id}>
                  <Cell className="text-muted">#{v.id}</Cell>
                  <Cell className="text-ink">
                    {v.conductorNombre ?? (
                      <span className="text-muted">Sin asignar</span>
                    )}
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
                  <Cell>
                    <div className="flex justify-end gap-2">
                      {CANCELABLES.includes(v.estadoViaje) && (
                        <Button
                          variant="danger"
                          onClick={() => cancelar(v.id)}
                        >
                          Cancelar
                        </Button>
                      )}
                      {v.estadoViaje === 'FINALIZADO' && (
                        <Button
                          variant="outline"
                          onClick={() => setCalificar(v)}
                        >
                          Calificar
                        </Button>
                      )}
                    </div>
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

      <CalificarModal
        viaje={calificar}
        onClose={() => setCalificar(null)}
        onDone={() => {
          setCalificar(null);
          cargar(page);
        }}
      />
    </div>
  );
}

function CalificarModal({ viaje, onClose, onDone }) {
  const toast = useToast();
  const [puntuacion, setPuntuacion] = useState(0);
  const [hover, setHover] = useState(0);
  const [comentario, setComentario] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setPuntuacion(0);
    setHover(0);
    setComentario('');
  }, [viaje]);

  if (!viaje) return null;

  const enviar = async () => {
    if (puntuacion < 1) {
      toast.error('Selecciona una puntuación');
      return;
    }
    setSaving(true);
    try {
      await clienteApi.calificarConductor(viaje.id, {
        puntuacion,
        comentario,
      });
      toast.success('¡Gracias por tu calificación!');
      onDone();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo enviar la calificación');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={!!viaje}
      onClose={onClose}
      title={`Calificar viaje #${viaje.id}`}
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Cancelar
          </Button>
          <Button onClick={enviar} loading={saving}>
            Enviar
          </Button>
        </>
      }
    >
      <div className="flex flex-col items-center gap-5">
        <div className="flex gap-2">
          {[1, 2, 3, 4, 5].map((i) => (
            <button
              key={i}
              type="button"
              onClick={() => setPuntuacion(i)}
              onMouseEnter={() => setHover(i)}
              onMouseLeave={() => setHover(0)}
              className="transition-transform duration-150 hover:scale-110"
              aria-label={`${i} estrellas`}
            >
              <IconStar
                filled={i <= (hover || puntuacion)}
                width={32}
                height={32}
              />
            </button>
          ))}
        </div>
        <textarea
          value={comentario}
          onChange={(e) => setComentario(e.target.value)}
          rows={4}
          placeholder="Comparte tu experiencia (opcional)…"
          className="w-full resize-none rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60"
        />
      </div>
    </Modal>
  );
}

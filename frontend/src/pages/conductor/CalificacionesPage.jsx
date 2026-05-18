import { useEffect, useState, useCallback } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Button from '../../components/ui/Button.jsx';
import Stars from '../../components/ui/Stars.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { conductorApi } from '../../api/conductor.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const fmtFecha = (f) => {
  if (!f) return '';
  try {
    return new Date(f).toLocaleDateString('es-CO', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return f;
  }
};

const SIZE = 10;

export default function CalificacionesPage() {
  const toast = useToast();
  const [loading, setLoading] = useState(true);
  const [promedio, setPromedio] = useState({
    promedio: 0,
    totalCalificaciones: 0,
  });
  const [page, setPage] = useState(0);
  const [data, setData] = useState({
    content: [],
    totalElements: 0,
    totalPages: 1,
  });

  const cargarLista = useCallback(
    (pg) => {
      setLoading(true);
      conductorApi
        .calificaciones({ page: pg, size: SIZE })
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
        .catch(() => toast.error('Error al cargar calificaciones'))
        .finally(() => setLoading(false));
    },
    [toast]
  );

  useEffect(() => {
    conductorApi
      .promedioCalificaciones()
      .then(setPromedio)
      .catch(() => {});
  }, []);

  useEffect(() => {
    cargarLista(page);
  }, [page, cargarLista]);

  return (
    <div>
      <PageHeader
        title="Mis Calificaciones"
        subtitle="Valoraciones recibidas de los clientes"
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card className="flex flex-col items-center justify-center p-8 text-center">
          <span className="font-serif text-6xl text-ink">
            {Number(promedio.promedio ?? 0).toFixed(1)}
          </span>
          <div className="mt-3">
            <Stars value={promedio.promedio ?? 0} />
          </div>
          <p className="mt-3 text-sm text-muted">
            {promedio.totalCalificaciones ?? 0} calificación(es)
          </p>
        </Card>

        <Card className="p-6 lg:col-span-2">
          {loading ? (
            <div className="flex h-48 items-center justify-center">
              <Spinner size="h-8 w-8" />
            </div>
          ) : data.content.length === 0 ? (
            <div className="flex h-48 items-center justify-center text-muted">
              Aún no tienes calificaciones
            </div>
          ) : (
            <div className="flex flex-col divide-y divide-line/60">
              {data.content.map((c) => (
                <div key={c.id} className="py-4 first:pt-0 last:pb-0">
                  <div className="flex items-center justify-between">
                    <Stars value={c.puntuacion ?? 0} />
                    <span className="text-xs text-muted">
                      {fmtFecha(c.fechaCalificacion ?? c.fecha)}
                    </span>
                  </div>
                  {c.comentario ? (
                    <p className="mt-2 text-sm text-subtle">
                      “{c.comentario}”
                    </p>
                  ) : (
                    <p className="mt-2 text-sm italic text-muted">
                      Sin comentario
                    </p>
                  )}
                  <p className="mt-1 text-xs text-muted">
                    Viaje #{c.viajeId ?? '—'}
                  </p>
                </div>
              ))}
            </div>
          )}

          {data.totalPages > 1 && (
            <div className="mt-5 flex items-center justify-between border-t border-line pt-4">
              <p className="text-sm text-muted">
                Página {page + 1} de {data.totalPages}
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
                  disabled={page + 1 >= data.totalPages}
                  onClick={() => setPage((p) => p + 1)}
                >
                  Siguiente
                </Button>
              </div>
            </div>
          )}
        </Card>
      </div>
    </div>
  );
}

import { useEffect, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Button from '../../components/ui/Button.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { notificacionesApi } from '../../api/notificaciones.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const fmtTime = (f) => {
  if (!f) return '';
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

export default function NotificacionesPage() {
  const toast = useToast();
  const [loading, setLoading] = useState(true);
  const [items, setItems] = useState([]);

  const cargar = () =>
    notificacionesApi
      .listar()
      .then((d) => setItems(Array.isArray(d) ? d : d?.content ?? []))
      .finally(() => setLoading(false));

  useEffect(() => {
    cargar();
  }, []);

  const marcarTodas = async () => {
    try {
      await notificacionesApi.marcarTodasLeidas();
      toast.success('Todas marcadas como leídas');
      setItems((prev) => prev.map((n) => ({ ...n, leida: true })));
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo actualizar');
    }
  };

  return (
    <div>
      <PageHeader
        title="Centro de Notificaciones"
        subtitle="Alertas y mensajes del sistema"
        actions={
          <Button variant="outline" onClick={marcarTodas}>
            Marcar todas como leídas
          </Button>
        }
      />

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : items.length === 0 ? (
        <Card className="flex h-48 items-center justify-center text-muted">
          No tienes notificaciones
        </Card>
      ) : (
        <div className="flex flex-col gap-2.5">
          {items.map((n) => (
            <Card
              key={n.id}
              className={`flex items-start gap-4 p-5 transition-colors duration-200 ${
                !n.leida ? 'border-gold/25' : ''
              }`}
            >
              <span
                className={`mt-1.5 h-2.5 w-2.5 shrink-0 rounded-full ${
                  n.leida ? 'bg-muted' : 'bg-gold'
                }`}
              />
              <div className="flex-1">
                <p className="font-medium text-ink">
                  {n.titulo ?? n.tipoNotificacion ?? 'Notificación'}
                </p>
                <p className="mt-0.5 text-sm text-muted">{n.mensaje}</p>
              </div>
              <span className="shrink-0 text-xs text-muted">
                {fmtTime(n.fechaCreacion ?? n.fecha)}
              </span>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}

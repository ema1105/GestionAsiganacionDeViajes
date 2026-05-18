import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import PageHeader from '../../components/ui/PageHeader.jsx';
import StatCard from '../../components/ui/StatCard.jsx';
import Card from '../../components/ui/Card.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import {
  IconChart,
  IconDrivers,
  IconClients,
  IconBell,
} from '../../components/icons/Icons.jsx';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const EN_CURSO = ['ACEPTADO', 'EN_CAMINO', 'EN_CURSO'];
const EN_ESPERA = ['SOLICITADO', 'BUSCANDO_CONDUCTOR'];

const ACCESOS = [
  {
    to: '/admin/estadisticas',
    label: 'Estadísticas',
    desc: 'Métricas y analítica de la operación',
    icon: IconChart,
  },
  {
    to: '/admin/conductores',
    label: 'Conductores',
    desc: 'Gestiona la flota de conductores',
    icon: IconDrivers,
  },
  {
    to: '/admin/clientes',
    label: 'Clientes',
    desc: 'Usuarios registrados en la plataforma',
    icon: IconClients,
  },
  {
    to: '/admin/notificaciones',
    label: 'Notificaciones',
    desc: 'Alertas y mensajes del sistema',
    icon: IconBell,
  },
];

export default function AdminDashboardPage() {
  const toast = useToast();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [op, setOp] = useState(null);

  useEffect(() => {
    (async () => {
      const res = await Promise.allSettled([
        adminApi.listarViajes({ size: 300 }),
        adminApi.listarConductores(),
      ]);
      const viajesPage =
        res[0].status === 'fulfilled' ? res[0].value : { content: [] };
      const conductores =
        res[1].status === 'fulfilled' ? res[1].value : [];

      const content = Array.isArray(viajesPage)
        ? viajesPage
        : (viajesPage?.content ?? []);
      const condArr = Array.isArray(conductores)
        ? conductores
        : (conductores?.content ?? []);

      const hoy = new Date().toISOString().slice(0, 10);

      setOp({
        enCurso: content.filter((v) => EN_CURSO.includes(v.estadoViaje))
          .length,
        enEspera: content.filter((v) => EN_ESPERA.includes(v.estadoViaje))
          .length,
        disponibles: condArr.filter(
          (c) => c.disponibilidad === true && c.activo !== false
        ).length,
        finalizadosHoy: content.filter(
          (v) =>
            v.estadoViaje === 'FINALIZADO' &&
            String(v.fechaFinalizacion ?? v.fechaSolicitud ?? '').startsWith(
              hoy
            )
        ).length,
      });

      if (res.some((r) => r.status === 'rejected')) {
        toast.info('Estado operativo con datos parciales');
      }
      setLoading(false);
    })();
  }, [toast]);

  if (loading || !op) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <Spinner size="h-8 w-8" />
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Estadísticas"
        subtitle="Estado operativo general del sistema GAV"
      />

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Viajes en curso" value={op.enCurso} />
        <StatCard label="Solicitudes en espera" value={op.enEspera} />
        <StatCard label="Conductores disponibles" value={op.disponibles} />
        <StatCard label="Finalizados hoy" value={op.finalizadosHoy} />
      </div>

      <h3 className="mb-4 mt-8 font-serif text-xl text-ink">
        Accesos rápidos
      </h3>
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
        {ACCESOS.map((a) => {
          const Icon = a.icon;
          return (
            <Card
              key={a.to}
              onClick={() => navigate(a.to)}
              className="lift cursor-pointer p-6"
            >
              <div className="mb-4 flex h-11 w-11 items-center justify-center rounded-lg border border-gold/20 bg-gold/10 text-gold">
                <Icon width={20} height={20} />
              </div>
              <p className="font-medium text-ink">{a.label}</p>
              <p className="mt-1 text-sm text-muted">{a.desc}</p>
            </Card>
          );
        })}
      </div>
    </div>
  );
}

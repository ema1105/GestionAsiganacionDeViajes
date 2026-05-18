import { useEffect, useState, useCallback } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import StatCard from '../../components/ui/StatCard.jsx';
import Card from '../../components/ui/Card.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { conductorApi } from '../../api/conductor.api.js';
import { useToast } from '../../context/ToastContext.jsx';
import { useRoleGate } from '../../hooks/useRoleGate.js';
import { ROLES } from '../../constants/roles.js';

const fmtMoney = (n) =>
  new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n || 0);

// Extrae un número de respuestas que pueden ser número plano u objeto.
const num = (x, key) => {
  if (x == null) return 0;
  if (typeof x === 'number') return x;
  return x[key] ?? x.total ?? x.cantidad ?? 0;
};

const hoyISO = () => new Date().toISOString().slice(0, 10);

export default function GananciasPage() {
  const toast = useToast();
  const { authorized } = useRoleGate(ROLES.CONDUCTOR);
  const [loading, setLoading] = useState(true);
  const [fecha, setFecha] = useState(hoyISO());
  const [stats, setStats] = useState(null);

  const cargar = useCallback(
    async (f) => {
      setLoading(true);
      const d = new Date(f);
      const anio = d.getFullYear();
      const mes = d.getMonth() + 1;

      const res = await Promise.allSettled([
        conductorApi.gananciasDia(f),
        conductorApi.gananciasMes(anio, mes),
        conductorApi.viajesDia(f),
        conductorApi.viajesMes(anio, mes),
      ]);
      const v = (i) => (res[i].status === 'fulfilled' ? res[i].value : null);

      setStats({
        gananciaDia: num(v(0), 'totalGanancias'),
        gananciaMes: num(v(1), 'totalGanancias'),
        viajesDia: num(v(2), 'cantidad') || num(v(0), 'cantidadViajes'),
        viajesMes: num(v(3), 'cantidad') || num(v(1), 'cantidadViajes'),
      });

      if (res.some((r) => r.status === 'rejected')) {
        toast.info('Algunas métricas usan datos parciales');
      }
      setLoading(false);
    },
    [toast]
  );

  useEffect(() => {
    if (!authorized) return;
    cargar(fecha);
  }, [authorized, fecha, cargar]);

  return (
    <div>
      <PageHeader
        title="Ganancias"
        subtitle="Tus ingresos y viajes — datos reales del backend"
        actions={
          <input
            type="date"
            value={fecha}
            max={hoyISO()}
            onChange={(e) => setFecha(e.target.value)}
            className="rounded-lg border border-line bg-surface px-3.5 py-2.5 text-sm text-ink outline-none focus:border-gold/60"
          />
        }
      />

      {loading || !stats ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : (
        <>
          <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard
              label="Ganancia del día"
              value={fmtMoney(stats.gananciaDia)}
            />
            <StatCard
              label="Ganancia del mes"
              value={fmtMoney(stats.gananciaMes)}
            />
            <StatCard label="Viajes del día" value={stats.viajesDia} />
            <StatCard label="Viajes del mes" value={stats.viajesMes} />
          </div>

          <Card className="mt-6 p-6">
            <h3 className="mb-2 font-serif text-xl text-ink">Resumen</h3>
            <p className="text-sm text-muted">
              El{' '}
              <span className="text-subtle">
                {new Date(fecha).toLocaleDateString('es-CO', {
                  day: '2-digit',
                  month: 'long',
                  year: 'numeric',
                })}
              </span>{' '}
              realizaste{' '}
              <span className="text-gold">{stats.viajesDia}</span> viaje(s)
              generando{' '}
              <span className="text-gold">
                {fmtMoney(stats.gananciaDia)}
              </span>
              . En el mes acumulas{' '}
              <span className="text-gold">
                {fmtMoney(stats.gananciaMes)}
              </span>{' '}
              en <span className="text-gold">{stats.viajesMes}</span> viaje(s).
            </p>
          </Card>
        </>
      )}
    </div>
  );
}

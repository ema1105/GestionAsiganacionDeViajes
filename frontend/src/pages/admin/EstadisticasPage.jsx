import { useEffect, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import StatCard from '../../components/ui/StatCard.jsx';
import Card from '../../components/ui/Card.jsx';
import BarChart from '../../components/ui/BarChart.jsx';
import Table, { Row, Cell } from '../../components/ui/Table.jsx';
import Badge, { estadoViajeTone } from '../../components/ui/Badge.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { IconChart } from '../../components/icons/Icons.jsx';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const fmtMoney = (n) =>
  new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n || 0);

const DIAS = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];

// Calcula variación porcentual real entre dos valores.
// Devuelve null si no hay base previa fiable (no se inventan porcentajes).
function variacion(actual, previo) {
  if (previo == null || previo <= 0 || actual == null) return null;
  const pct = ((actual - previo) / previo) * 100;
  return { delta: `${Math.abs(pct).toFixed(1)}%`, positive: pct >= 0 };
}

export default function EstadisticasPage() {
  const toast = useToast();
  const [loading, setLoading] = useState(true);
  const [kpis, setKpis] = useState(null);
  const [serieDias, setSerieDias] = useState([]);
  const [serieEstados, setSerieEstados] = useState([]);
  const [ultimos, setUltimos] = useState([]);

  useEffect(() => {
    (async () => {
      const now = new Date();
      const anio = now.getFullYear();
      const mes = now.getMonth() + 1;
      const prevMes = mes === 1 ? 12 : mes - 1;
      const prevAnio = mes === 1 ? anio - 1 : anio;

      const desde = new Date(now);
      desde.setDate(desde.getDate() - 6);
      const iso = (d) => d.toISOString().slice(0, 10);

      const res = await Promise.allSettled([
        adminApi.listarViajes({ size: 300 }),
        adminApi.listarConductores(),
        adminApi.listarClientes(),
        adminApi.gananciasMes(anio, mes),
        adminApi.gananciasMes(prevAnio, prevMes),
        adminApi.viajesPorDia(iso(desde), iso(now)),
      ]);

      const val = (i, def) =>
        res[i].status === 'fulfilled' ? res[i].value : def;

      const viajesPage = val(0, { content: [], totalElements: 0 });
      const conductores = val(1, []);
      const clientes = val(2, []);
      const gMesActual = val(3, null);
      const gMesPrev = val(4, null);
      const porDia = val(5, []);

      const content = Array.isArray(viajesPage)
        ? viajesPage
        : (viajesPage?.content ?? []);
      const totalViajes = Array.isArray(viajesPage)
        ? viajesPage.length
        : (viajesPage?.totalElements ?? content.length);

      const conductoresArr = Array.isArray(conductores)
        ? conductores
        : (conductores?.content ?? []);
      const conductoresActivos = conductoresArr.filter(
        (c) => c.activo !== false
      ).length;

      const clientesArr = Array.isArray(clientes)
        ? clientes
        : (clientes?.content ?? []);

      // Ingresos: dato real del backend; fallback a suma de finalizados.
      const ingresos =
        gMesActual?.totalGanancias ??
        content
          .filter((v) => v.estadoViaje === 'FINALIZADO')
          .reduce((s, v) => s + (v.precioCalculado || v.precio || 0), 0);

      setKpis({
        viajes: totalViajes,
        viajesVar: variacion(
          gMesActual?.cantidadViajes,
          gMesPrev?.cantidadViajes
        ),
        conductores: conductoresActivos,
        clientes: clientesArr.length,
        ingresos,
        ingresosVar: variacion(
          gMesActual?.totalGanancias,
          gMesPrev?.totalGanancias
        ),
      });

      // Serie 7 días: usa el endpoint real; si no, agrupa por fecha real.
      let dias = [];
      const arr = Array.isArray(porDia) ? porDia : (porDia?.content ?? []);
      if (arr.length > 0) {
        dias = arr.map((d) => ({
          label: DIAS[new Date(d.fecha).getDay()] ?? '',
          value: d.cantidad ?? d.total ?? 0,
        }));
      } else {
        const mapa = {};
        content.forEach((v) => {
          const f = v.fechaSolicitud ?? v.fechaInicio;
          if (!f) return;
          const k = String(f).slice(0, 10);
          mapa[k] = (mapa[k] || 0) + 1;
        });
        dias = Object.entries(mapa)
          .sort()
          .slice(-7)
          .map(([k, n]) => ({
            label: DIAS[new Date(k).getDay()] ?? '',
            value: n,
          }));
      }
      setSerieDias(dias);

      // Distribución real por estado de viaje.
      const porEstado = {};
      content.forEach((v) => {
        if (!v.estadoViaje) return;
        porEstado[v.estadoViaje] = (porEstado[v.estadoViaje] || 0) + 1;
      });
      setSerieEstados(
        Object.entries(porEstado).map(([k, n]) => ({
          label: k.slice(0, 4),
          value: n,
        }))
      );

      setUltimos(content.slice(0, 8));

      if (res.some((r) => r.status === 'rejected')) {
        toast.info('Algunas métricas usan datos parciales del backend');
      }
      setLoading(false);
    })();
  }, [toast]);

  if (loading || !kpis) {
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
        subtitle="Centro analítico de la operación GAV — solo visualización"
      />

      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Total de Viajes" value={kpis.viajes} />
        <StatCard label="Conductores Activos" value={kpis.conductores} />
        <StatCard label="Clientes Registrados" value={kpis.clientes} />
        <StatCard
          label="Ingresos del Mes"
          value={fmtMoney(kpis.ingresos)}
          delta={kpis.ingresosVar?.delta}
          positive={kpis.ingresosVar?.positive ?? true}
        />
      </div>

      <div className="mt-6 grid grid-cols-1 gap-5 lg:grid-cols-2">
        <Card className="p-6">
          <h3 className="mb-1 font-serif text-xl text-ink">
            Viajes últimos 7 días
          </h3>
          <p className="mb-6 text-xs text-muted">Datos reales del periodo</p>
          {serieDias.length ? (
            <BarChart data={serieDias} />
          ) : (
            <p className="py-16 text-center text-sm text-muted">
              Sin viajes en el periodo
            </p>
          )}
        </Card>
        <Card className="p-6">
          <h3 className="mb-1 font-serif text-xl text-ink">
            Distribución por estado
          </h3>
          <p className="mb-6 text-xs text-muted">
            Sobre los viajes registrados
          </p>
          {serieEstados.length ? (
            <BarChart data={serieEstados} />
          ) : (
            <p className="py-16 text-center text-sm text-muted">
              Sin datos suficientes
            </p>
          )}
        </Card>
      </div>

      {/* Espacio reservado para Power BI */}
      <div className="mt-6">
        <Card className="flex min-h-[280px] flex-col items-center justify-center gap-3 border-dashed border-gold/25 p-10 text-center">
          <div className="flex h-14 w-14 items-center justify-center rounded-full border border-gold/25 bg-gold/10 text-gold">
            <IconChart width={26} height={26} />
          </div>
          <h3 className="font-serif text-2xl text-ink">
            Analítica avanzada — Power BI
          </h3>
          <p className="max-w-md text-sm text-muted">
            Contenedor reservado para la futura integración del dashboard de
            Microsoft Power BI. Aquí se incrustará el panel interactivo de
            analítica corporativa.
          </p>
          <span className="mt-1 rounded-full border border-line px-3 py-1 text-[11px] uppercase tracking-wider text-muted">
            Próximamente
          </span>
        </Card>
      </div>

      <div className="mt-6">
        <h3 className="mb-4 font-serif text-xl text-ink">Últimos viajes</h3>
        <Table
          head={['ID', 'Cliente', 'Conductor', 'Precio', 'Estado']}
          empty="Aún no hay viajes registrados"
        >
          {ultimos.length > 0 &&
            ultimos.map((v) => (
              <Row key={v.id}>
                <Cell className="text-muted">#{v.id}</Cell>
                <Cell className="text-ink">
                  {v.clienteNombre ?? `Cliente ${v.clienteId ?? '—'}`}
                </Cell>
                <Cell>
                  {v.conductorNombre ?? (
                    <span className="text-muted">Sin asignar</span>
                  )}
                </Cell>
                <Cell className="text-ink">
                  {fmtMoney(v.precioCalculado ?? v.precio)}
                </Cell>
                <Cell>
                  <Badge tone={estadoViajeTone(v.estadoViaje)}>
                    {v.estadoViaje}
                  </Badge>
                </Cell>
              </Row>
            ))}
        </Table>
      </div>
    </div>
  );
}

import { useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Button from '../../components/ui/Button.jsx';
import Badge from '../../components/ui/Badge.jsx';
import Table, { Row, Cell } from '../../components/ui/Table.jsx';
import { IconActivity, IconDrivers, IconTrip } from '../../components/icons/Icons.jsx';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

// Normaliza la respuesta del microservicio (Jackson serializa con snake_case
// por los @JsonProperty del DTO; toleramos también camelCase por robustez).
function normalizar(raw) {
  if (!raw) return null;
  return {
    asignaciones: (raw.asignaciones ?? []).map((a) => ({
      conductorId: a.conductor_id ?? a.conductorId,
      viajeId: a.viaje_id ?? a.viajeId,
    })),
    viajesCubiertos: raw.viajes_cubiertos ?? raw.viajesCubiertos ?? 0,
    totalConductores:
      raw.total_conductores_disponibles ?? raw.totalConductoresDisponibles ?? 0,
    totalViajes:
      raw.total_viajes_pendientes ?? raw.totalViajesPendientes ?? 0,
    status: raw.status ?? '—',
  };
}

// Tono del badge según el estado del solver ILP.
function statusTone(status) {
  const s = (status ?? '').toLowerCase();
  if (s.includes('optimal')) return 'green';
  if (s.includes('feasible')) return 'gold';
  if (s.includes('infeasible') || s.includes('error')) return 'red';
  return 'neutral';
}

// Tarjeta métrica ejecutiva premium.
function MetricCard({ label, value, sub, accent = 'text-ink', icon: Icon }) {
  return (
    <Card className="lift p-5 sm:p-6">
      <div className="flex items-start justify-between gap-3">
        <p className="text-[11px] uppercase tracking-wider text-muted">
          {label}
        </p>
        {Icon && (
          <span className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg bg-gold/10">
            <Icon width={15} height={15} className="text-gold" />
          </span>
        )}
      </div>
      <p className={`mt-3 font-serif text-3xl sm:text-4xl ${accent}`}>
        {value}
      </p>
      {sub && <p className="mt-1 text-xs text-muted">{sub}</p>}
    </Card>
  );
}

export default function AsignacionPage() {
  const toast = useToast();
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);
  // Estado informativo (no error): datos insuficientes (HTTP 422).
  const [aviso, setAviso] = useState(null);
  const [ejecutado, setEjecutado] = useState(false);

  const ejecutar = async () => {
    setLoading(true);
    setError(null);
    setAviso(null);
    try {
      const raw = await adminApi.ejecutarAsignacion();
      const data = normalizar(raw);
      setResult(data);
      setEjecutado(true);
      toast.success(
        `Optimización completada — ${data.viajesCubiertos} viaje(s) asignado(s)`
      );
    } catch (e) {
      setResult(null);
      // 422 = validación de negocio (datos insuficientes): es un estado
      // controlado e informativo, NO un fallo del sistema.
      if (e?.status === 422) {
        setAviso(
          e?.mensaje ||
            'No hay datos suficientes para ejecutar la optimización.'
        );
        toast.info('No hay datos suficientes para optimizar');
      } else {
        setError(
          e?.mensaje ||
            'No se pudo ejecutar el modelo. Verifica que el microservicio de optimización esté disponible.'
        );
        toast.error('Falló la ejecución del modelo');
      }
    } finally {
      setLoading(false);
    }
  };

  const cobertura =
    result && result.totalViajes > 0
      ? Math.round((result.viajesCubiertos / result.totalViajes) * 100)
      : 0;

  return (
    <div>
      <PageHeader
        title="Modelo de Asignación"
        subtitle="Optimización matemática (ILP) de conductores a viajes pendientes"
      />

      {/* ── Panel ejecutivo de ejecución ── */}
      <Card className="relative overflow-hidden p-6 sm:p-8">
        {/* Glow decorativo */}
        <div className="pointer-events-none absolute -right-20 -top-20 h-56 w-56 rounded-full bg-gold/5 blur-3xl" />

        <div className="relative flex flex-col gap-6 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-start gap-4">
            <span
              className={`flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-xl border border-gold/20 bg-gold/5 transition-transform duration-500 ${
                loading ? 'animate-pulse' : ''
              }`}
            >
              <IconActivity width={22} height={22} className="text-gold" />
            </span>
            <div>
              <h2 className="font-serif text-xl text-ink sm:text-2xl">
                Optimizador de asignaciones
              </h2>
              <p className="mt-1 max-w-xl text-sm text-muted">
                Ejecuta el modelo de programación lineal entera para asignar de
                forma óptima los conductores disponibles a los viajes
                pendientes, maximizando la cobertura del servicio.
              </p>
            </div>
          </div>

          <Button
            variant="gold"
            loading={loading}
            onClick={ejecutar}
            className="w-full sm:w-auto"
          >
            {loading ? 'Optimizando…' : 'Ejecutar modelo'}
          </Button>
        </div>

        {/* Barra de progreso animada durante la ejecución */}
        {loading && (
          <div className="relative mt-6 h-1 overflow-hidden rounded-full bg-line">
            <div className="absolute inset-y-0 left-0 w-1/4 animate-progress-indeterminate rounded-full bg-gold/70" />
          </div>
        )}
      </Card>

      {/* ── Aviso controlado: datos insuficientes (422) ── */}
      {aviso && !loading && (
        <Card className="mt-6 border-amber-500/30 p-6 animate-fade-in">
          <div className="flex items-start gap-4">
            <span className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-amber-500/10 text-lg text-amber-400">
              i
            </span>
            <div>
              <p className="font-medium text-ink">
                No hay datos suficientes para optimizar
              </p>
              <p className="mt-1 text-sm text-muted">{aviso}</p>
              <button
                onClick={ejecutar}
                className="mt-3 text-[13px] text-gold underline underline-offset-2 hover:text-gold/80"
              >
                Volver a intentar
              </button>
            </div>
          </div>
        </Card>
      )}

      {/* ── Estado de error ── */}
      {error && !loading && (
        <Card className="mt-6 border-red-500/30 p-6 animate-fade-in">
          <div className="flex items-start gap-4">
            <span className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-red-500/10 text-lg text-red-400">
              !
            </span>
            <div>
              <p className="font-medium text-ink">
                No se pudo completar la optimización
              </p>
              <p className="mt-1 text-sm text-muted">{error}</p>
              <button
                onClick={ejecutar}
                className="mt-3 text-[13px] text-gold underline underline-offset-2 hover:text-gold/80"
              >
                Reintentar
              </button>
            </div>
          </div>
        </Card>
      )}

      {/* ── Estado vacío inicial ── */}
      {!ejecutado && !loading && !error && !aviso && (
        <Card className="mt-6 flex flex-col items-center justify-center gap-3 p-12 text-center animate-fade-in">
          <span className="flex h-16 w-16 items-center justify-center rounded-2xl border border-gold/15 bg-gold/5">
            <IconActivity width={28} height={28} className="text-gold/50" />
          </span>
          <p className="font-serif text-xl text-ink">
            Modelo listo para ejecutar
          </p>
          <p className="max-w-md text-sm text-muted">
            Pulsa «Ejecutar modelo» para calcular la asignación óptima. Los
            resultados y métricas aparecerán aquí.
          </p>
        </Card>
      )}

      {/* ── Resultados ── */}
      {result && !loading && (
        <div className="mt-6 space-y-6 animate-fade-in">
          {/* Métricas ejecutivas */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <MetricCard
              label="Viajes cubiertos"
              value={result.viajesCubiertos}
              sub={`de ${result.totalViajes} pendientes`}
              accent="text-gold"
              icon={IconTrip}
            />
            <MetricCard
              label="Total de viajes"
              value={result.totalViajes}
              sub="solicitudes pendientes"
              icon={IconTrip}
            />
            <MetricCard
              label="Cobertura"
              value={`${cobertura}%`}
              sub="del total de viajes"
              accent={
                cobertura >= 80
                  ? 'text-emerald-400'
                  : cobertura >= 50
                  ? 'text-gold'
                  : 'text-red-400'
              }
              icon={IconActivity}
            />
            <MetricCard
              label="Conductores"
              value={result.totalConductores}
              sub="disponibles en cola"
              icon={IconDrivers}
            />
          </div>

          {/* Estado del modelo */}
          <Card className="flex flex-wrap items-center justify-between gap-3 p-5">
            <div>
              <p className="text-[11px] uppercase tracking-wider text-muted">
                Estado del solver
              </p>
              <p className="mt-1 text-sm text-subtle">
                Resultado reportado por el microservicio de optimización
              </p>
            </div>
            <Badge tone={statusTone(result.status)} className="text-[12px]">
              {result.status}
            </Badge>
          </Card>

          {/* Tabla de asignaciones */}
          <div>
            <div className="mb-3 flex items-center justify-between">
              <h3 className="font-serif text-lg text-ink">
                Asignaciones generadas
              </h3>
              <span className="text-sm text-muted">
                {result.asignaciones.length}{' '}
                {result.asignaciones.length === 1 ? 'par' : 'pares'} conductor ↔
                viaje
              </span>
            </div>

            <Table
              head={['#', 'Conductor', '', 'Viaje', 'Estado']}
              empty="El modelo no generó asignaciones (no hay conductores o viajes compatibles)"
            >
              {result.asignaciones.map((a, i) => (
                <Row key={`${a.conductorId}-${a.viajeId}`}>
                  <Cell className="font-mono text-[12px] text-muted">
                    {i + 1}
                  </Cell>
                  <Cell>
                    <div className="flex items-center gap-3">
                      <span className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full border border-gold/25 bg-gold/10 text-gold">
                        <IconDrivers width={15} height={15} />
                      </span>
                      <div className="leading-tight">
                        <p className="text-sm font-medium text-ink">
                          Conductor #{a.conductorId}
                        </p>
                        <p className="text-[11px] text-muted">
                          Asignado por el modelo
                        </p>
                      </div>
                    </div>
                  </Cell>
                  <Cell className="text-center text-gold">→</Cell>
                  <Cell>
                    <div className="flex items-center gap-3">
                      <span className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full border border-sky-500/25 bg-sky-500/10 text-sky-400">
                        <IconTrip width={15} height={15} />
                      </span>
                      <div className="leading-tight">
                        <p className="text-sm font-medium text-ink">
                          Viaje #{a.viajeId}
                        </p>
                        <p className="text-[11px] text-muted">
                          Viaje pendiente
                        </p>
                      </div>
                    </div>
                  </Cell>
                  <Cell>
                    <Badge tone="green">Asignado</Badge>
                  </Cell>
                </Row>
              ))}
            </Table>
          </div>
        </div>
      )}
    </div>
  );
}

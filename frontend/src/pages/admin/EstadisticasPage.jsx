import { useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import { IconChart } from '../../components/icons/Icons.jsx';

// Enlace oficial del informe corporativo publicado en Power BI.
const POWER_BI_URL =
  'https://app.powerbi.com/view?r=eyJrIjoiNDFjMWEyZDgtYTU4NC00MWNmLWEyNWQtMThiY2ZkZDBiNmE1IiwidCI6IjlkMTJiZjNmLWU0ZjYtNDdhYi05MTJmLTFhMmYwZmM0OGFhNCIsImMiOjR9';

// Vista exclusivamente dedicada al dashboard de Power BI.
// Sin KPIs ni métricas propias: toda la analítica viene del embed corporativo.
export default function EstadisticasPage() {
  const [cargando, setCargando] = useState(true);

  return (
    <div className="flex flex-col gap-6">
      <PageHeader
        title="Dashboard"
        subtitle="Analítica corporativa integrada — Microsoft Power BI"
      />

      {/* ── Contenedor principal Power BI ── */}
      <div className="relative flex flex-1 flex-col overflow-hidden rounded-2xl border border-line bg-surface shadow-premium">

        {/* Barra de cabecera estilo frame corporativo */}
        <div className="flex items-center justify-between border-b border-line px-6 py-3.5">
          <div className="flex items-center gap-3">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gold/10">
              <IconChart width={16} height={16} className="text-gold" />
            </div>
            <div className="leading-tight">
              <p className="text-sm font-medium text-ink">GAV Analytics</p>
              <p className="text-[11px] text-muted">
                Microsoft Power BI — Embedded
              </p>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <span className="inline-flex items-center gap-1.5 rounded-full border border-emerald-500/20 bg-emerald-500/10 px-2.5 py-1 text-[11px] font-medium text-emerald-400">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
              Conectado
            </span>
            <a
              href={POWER_BI_URL}
              target="_blank"
              rel="noopener noreferrer"
              className="rounded-lg border border-line px-3 py-1.5 text-[12px] font-medium text-subtle transition-colors duration-200 hover:border-gold/40 hover:text-gold"
            >
              Abrir en Power BI ↗
            </a>
          </div>
        </div>

        {/* Embed responsive — ocupa el espacio principal de la vista */}
        <div className="relative min-h-[78vh] flex-1 bg-[#0D0D0D]">
          {cargando && (
            <div className="absolute inset-0 z-10 flex flex-col items-center justify-center gap-4 bg-[#0D0D0D]">
              <div className="relative">
                <div className="flex h-16 w-16 items-center justify-center rounded-2xl border border-gold/20 bg-gold/5">
                  <IconChart width={28} height={28} className="text-gold/60" />
                </div>
                <div className="absolute -inset-2 rounded-2xl border border-gold/10 animate-pulse" />
              </div>
              <p className="text-sm text-muted">Cargando informe analítico…</p>
            </div>
          )}
          <iframe
            title="GAV Analytics — Power BI"
            src={POWER_BI_URL}
            className="absolute inset-0 h-full w-full border-0"
            allowFullScreen
            onLoad={() => setCargando(false)}
          />
        </div>
      </div>
    </div>
  );
}

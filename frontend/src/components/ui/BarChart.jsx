// Gráfico de barras minimalista sin dependencias externas.
// data: [{ label, value }]
export default function BarChart({ data = [] }) {
  const max = Math.max(...data.map((d) => d.value), 1);

  return (
    <div className="flex h-56 items-end justify-between gap-3">
      {data.map((d) => (
        <div key={d.label} className="flex flex-1 flex-col items-center gap-2">
          <div className="flex h-full w-full items-end">
            <div
              className="w-full rounded-t bg-gradient-to-t from-gold-dim/40 to-gold transition-all duration-500"
              style={{ height: `${(d.value / max) * 100}%` }}
              title={String(d.value)}
            />
          </div>
          <span className="text-[11px] text-muted">{d.label}</span>
        </div>
      ))}
    </div>
  );
}

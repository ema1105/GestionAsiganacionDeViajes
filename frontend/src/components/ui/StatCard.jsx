import Card from './Card.jsx';

// KPI card ejecutiva: cifra grande, etiqueta y delta porcentual.
export default function StatCard({ label, value, delta, positive = true }) {
  return (
    <Card className="p-6 lift">
      <p className="text-[11px] uppercase tracking-wider text-muted">{label}</p>
      <div className="mt-3 flex items-end justify-between">
        <span className="font-serif text-4xl text-ink">{value}</span>
        {delta != null && (
          <span
            className={`text-xs font-medium ${
              positive ? 'text-emerald-400' : 'text-red-400'
            }`}
          >
            {positive ? '▲' : '▼'} {delta}
          </span>
        )}
      </div>
    </Card>
  );
}

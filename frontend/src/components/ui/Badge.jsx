// Badge de estado con paleta semántica sobre fondo oscuro.
const TONES = {
  gold: 'bg-gold/10 text-gold border-gold/25',
  green: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/25',
  blue: 'bg-sky-500/10 text-sky-400 border-sky-500/25',
  red: 'bg-red-500/10 text-red-400 border-red-500/25',
  neutral: 'bg-muted/10 text-subtle border-line',
};

export default function Badge({ children, tone = 'neutral', className = '' }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5
        text-[11px] font-medium ${TONES[tone]} ${className}`}
    >
      {children}
    </span>
  );
}

// Mapea los estados de viaje del backend a un tono visual.
export function estadoViajeTone(estado) {
  switch (estado) {
    case 'FINALIZADO':
      return 'green';
    case 'EN_CURSO':
    case 'EN_CAMINO':
      return 'blue';
    case 'CANCELADO':
      return 'red';
    case 'ACEPTADO':
    case 'SOLICITADO':
    case 'BUSCANDO_CONDUCTOR':
      return 'gold';
    default:
      return 'neutral';
  }
}

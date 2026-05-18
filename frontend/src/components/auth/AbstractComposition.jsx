// Composición abstracta corporativa: arcos concéntricos suaves, líneas
// arquitectónicas finas y una curva de "trayecto" sutil con acento dorado.
// Sin ilustraciones literales: profundidad mediante degradados y geometría.
export default function AbstractComposition({ className = '' }) {
  return (
    <svg
      viewBox="0 0 600 600"
      fill="none"
      className={className}
      aria-hidden="true"
      preserveAspectRatio="xMidYMid slice"
    >
      <defs>
        <radialGradient id="depth" cx="35%" cy="30%" r="85%">
          <stop offset="0%" stopColor="#1A160F" />
          <stop offset="55%" stopColor="#0F0D0A" />
          <stop offset="100%" stopColor="#0A0A0A" />
        </radialGradient>
        <linearGradient id="goldLine" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" stopColor="#C9A96E" stopOpacity="0" />
          <stop offset="50%" stopColor="#C9A96E" stopOpacity="0.55" />
          <stop offset="100%" stopColor="#C9A96E" stopOpacity="0" />
        </linearGradient>
        <linearGradient id="goldSoft" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#C9A96E" stopOpacity="0.9" />
          <stop offset="100%" stopColor="#8A7548" stopOpacity="0.2" />
        </linearGradient>
      </defs>

      <rect width="600" height="600" fill="url(#depth)" />

      {/* Arcos concéntricos suaves */}
      <g stroke="#2A2520" strokeWidth="1" fill="none" opacity="0.7">
        <circle cx="430" cy="180" r="120" />
        <circle cx="430" cy="180" r="190" />
        <circle cx="430" cy="180" r="270" />
        <circle cx="430" cy="180" r="360" />
      </g>

      {/* Arco de acento dorado */}
      <circle
        cx="430"
        cy="180"
        r="190"
        stroke="url(#goldLine)"
        strokeWidth="1.5"
        fill="none"
      />

      {/* Líneas arquitectónicas finas */}
      <g stroke="#2A2520" strokeWidth="1" opacity="0.55">
        <path d="M0 470 H600" />
        <path d="M0 510 H600" />
        <path d="M120 600 V360" />
        <path d="M170 600 V410" />
      </g>

      {/* Curva de trayecto (movimiento, no edificios) */}
      <path
        d="M40 540 C 180 470, 250 520, 330 400 S 480 230, 560 120"
        stroke="url(#goldSoft)"
        strokeWidth="2"
        fill="none"
        strokeLinecap="round"
      />
      <circle cx="40" cy="540" r="4.5" fill="#C9A96E" />
      <circle cx="560" cy="120" r="4.5" fill="#C9A96E" />

      {/* Puntos de constelación tenues */}
      <g fill="#5C5247" opacity="0.6">
        <circle cx="120" cy="160" r="2" />
        <circle cx="220" cy="250" r="1.5" />
        <circle cx="90" cy="320" r="1.5" />
        <circle cx="500" cy="430" r="2" />
      </g>
    </svg>
  );
}

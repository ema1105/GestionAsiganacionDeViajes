// Set de iconos SVG minimalistas (stroke, currentColor) para toda la app.
// Tamaño por defecto 20px; heredan color del texto para el estado activo dorado.

const base = {
  width: 20,
  height: 20,
  viewBox: '0 0 24 24',
  fill: 'none',
  stroke: 'currentColor',
  strokeWidth: 1.6,
  strokeLinecap: 'round',
  strokeLinejoin: 'round',
};

// Isotipo GAV: carro minimalista sobre una ruta (viajes en Cartagena).
export function GavLogo({ size = 28 }) {
  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 48 48"
      fill="none"
      aria-hidden="true"
    >
      <circle cx="24" cy="24" r="22" stroke="#C9A96E" strokeWidth="1.5" />
      <path
        d="M14 28h20l-2.5-7a3 3 0 0 0-2.8-2h-9.4a3 3 0 0 0-2.8 2L14 28Z"
        stroke="#C9A96E"
        strokeWidth="1.6"
        strokeLinejoin="round"
      />
      <path d="M14 28v3M34 28v3" stroke="#C9A96E" strokeWidth="1.6" strokeLinecap="round" />
      <circle cx="18" cy="28" r="2.2" fill="#C9A96E" />
      <circle cx="30" cy="28" r="2.2" fill="#C9A96E" />
      <path
        d="M12 34c4-1.5 8-1.5 12 0s8 1.5 12 0"
        stroke="#C9A96E"
        strokeWidth="1.3"
        strokeLinecap="round"
        opacity="0.5"
      />
    </svg>
  );
}

export const IconDashboard = (p) => (
  <svg {...base} {...p}>
    <rect x="3" y="3" width="7" height="9" rx="1" />
    <rect x="14" y="3" width="7" height="5" rx="1" />
    <rect x="14" y="12" width="7" height="9" rx="1" />
    <rect x="3" y="16" width="7" height="5" rx="1" />
  </svg>
);

export const IconDrivers = (p) => (
  <svg {...base} {...p}>
    <circle cx="9" cy="8" r="3.2" />
    <path d="M3.5 20a5.5 5.5 0 0 1 11 0" />
    <path d="M16 11a3 3 0 1 0 0-6" />
    <path d="M17.5 20a5.5 5.5 0 0 0-3-4.9" />
  </svg>
);

export const IconClients = (p) => (
  <svg {...base} {...p}>
    <circle cx="12" cy="8" r="3.5" />
    <path d="M5 20a7 7 0 0 1 14 0" />
  </svg>
);

export const IconTrip = (p) => (
  <svg {...base} {...p}>
    <path d="M5 17h14l-1.8-5.5A3 3 0 0 0 14.3 9H9.7a3 3 0 0 0-2.9 2.5L5 17Z" />
    <path d="M5 17v2.5M19 17v2.5" />
    <circle cx="8.5" cy="17" r="1.4" />
    <circle cx="15.5" cy="17" r="1.4" />
  </svg>
);

export const IconBell = (p) => (
  <svg {...base} {...p}>
    <path d="M18 8a6 6 0 1 0-12 0c0 7-3 8-3 8h18s-3-1-3-8" />
    <path d="M13.7 21a2 2 0 0 1-3.4 0" />
  </svg>
);

export const IconUser = (p) => (
  <svg {...base} {...p}>
    <circle cx="12" cy="8" r="4" />
    <path d="M4 21a8 8 0 0 1 16 0" />
  </svg>
);

export const IconLogout = (p) => (
  <svg {...base} {...p}>
    <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
    <path d="M16 17l5-5-5-5M21 12H9" />
  </svg>
);

export const IconSearch = (p) => (
  <svg {...base} {...p}>
    <circle cx="11" cy="11" r="7" />
    <path d="m21 21-4.3-4.3" />
  </svg>
);

export const IconPlus = (p) => (
  <svg {...base} {...p}>
    <path d="M12 5v14M5 12h14" />
  </svg>
);

export const IconEdit = (p) => (
  <svg {...base} {...p}>
    <path d="M12 20h9" />
    <path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4Z" />
  </svg>
);

export const IconTrash = (p) => (
  <svg {...base} {...p}>
    <path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2m2 0v14a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V6" />
  </svg>
);

export const IconStar = ({ filled, ...p }) => (
  <svg
    width={14}
    height={14}
    viewBox="0 0 24 24"
    fill={filled ? '#C9A96E' : 'none'}
    stroke={filled ? '#C9A96E' : '#5C5247'}
    strokeWidth={1.4}
    {...p}
  >
    <path d="M12 2.5l2.9 5.9 6.5.95-4.7 4.58 1.1 6.47L12 17.4l-5.8 3.05 1.1-6.47L2.6 9.35l6.5-.95L12 2.5Z" />
  </svg>
);

export const IconStarLine = (p) => (
  <svg {...base} {...p}>
    <path d="M12 3l2.9 5.9 6.5.95-4.7 4.58 1.1 6.47L12 17.9l-5.8 3.05 1.1-6.47L2.6 9.85l6.5-.95L12 3Z" />
  </svg>
);

export const IconEye = (p) => (
  <svg {...base} width={18} height={18} {...p}>
    <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7-10-7-10-7Z" />
    <circle cx="12" cy="12" r="3" />
  </svg>
);

export const IconEyeOff = (p) => (
  <svg {...base} width={18} height={18} {...p}>
    <path d="M3 3l18 18" />
    <path d="M10.6 10.6a3 3 0 0 0 4 4" />
    <path d="M9.4 5.2A9.7 9.7 0 0 1 12 5c6.5 0 10 7 10 7a16 16 0 0 1-3 3.9M6 6.3A16 16 0 0 0 2 12s3.5 7 10 7a9.5 9.5 0 0 0 3.4-.6" />
  </svg>
);

export const IconDownload = (p) => (
  <svg {...base} {...p}>
    <path d="M12 3v12m0 0l-4-4m4 4l4-4" />
    <path d="M5 21h14" />
  </svg>
);

export const IconClose = (p) => (
  <svg {...base} {...p}>
    <path d="M6 6l12 12M18 6 6 18" />
  </svg>
);

export const IconMenu = (p) => (
  <svg {...base} {...p}>
    <path d="M3 6h18M3 12h18M3 18h18" />
  </svg>
);

export const IconChart = (p) => (
  <svg {...base} {...p}>
    <path d="M3 3v18h18" />
    <path d="M7 14l3.5-4 3 3L21 7" />
  </svg>
);

export const IconActivity = (p) => (
  <svg {...base} {...p}>
    <path d="M3 12h4l3 8 4-16 3 8h4" />
  </svg>
);

export const IconChat = (p) => (
  <svg {...base} {...p}>
    <path d="M21 12a8 8 0 0 1-8 8H7l-4 3v-7a8 8 0 0 1 8-8h2a8 8 0 0 1 8 8Z" />
    <path d="M9 11h6M9 14h4" />
  </svg>
);

export const IconSend = (p) => (
  <svg {...base} {...p}>
    <path d="M22 2 11 13M22 2l-7 20-4-9-9-4 20-7Z" />
  </svg>
);

export const IconWallet = (p) => (
  <svg {...base} {...p}>
    <path d="M3 7a2 2 0 0 1 2-2h12a2 2 0 0 1 2 2v1" />
    <path d="M3 7v10a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-6a2 2 0 0 0-2-2H5a2 2 0 0 1-2-2Z" />
    <circle cx="16.5" cy="13" r="1.4" />
  </svg>
);

export const IconCar = (p) => (
  <svg {...base} {...p}>
    <path d="M5 16h14l-1.6-6A3 3 0 0 0 14.5 8h-5A3 3 0 0 0 6.6 10L5 16Z" />
    <path d="M4 16h16v3a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-1H8v1a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-3Z" />
    <path d="M7 13h2M15 13h2" />
  </svg>
);

export const IconPin = (p) => (
  <svg {...base} {...p}>
    <path d="M12 21s7-5.5 7-11a7 7 0 1 0-14 0c0 5.5 7 11 7 11Z" />
    <circle cx="12" cy="10" r="2.5" />
  </svg>
);

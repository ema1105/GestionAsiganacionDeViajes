import { useEffect, useState } from 'react';

// Carga el script del Google Maps JavaScript API una sola vez para toda la app.
// Devuelve { loaded, error }. Si no hay clave configurada, error = true y los
// componentes de mapa muestran un fallback elegante (la app nunca se rompe).
const KEY = import.meta.env.VITE_GOOGLE_MAPS_API_KEY;
let promesa = null;

function cargarScript() {
  if (window.google?.maps) return Promise.resolve();
  if (promesa) return promesa;

  promesa = new Promise((resolve, reject) => {
    if (!KEY) {
      reject(new Error('Falta VITE_GOOGLE_MAPS_API_KEY'));
      return;
    }
    const s = document.createElement('script');
    s.src = `https://maps.googleapis.com/maps/api/js?key=${KEY}&libraries=marker`;
    s.async = true;
    s.defer = true;
    s.onload = () => resolve();
    s.onerror = () => reject(new Error('No se pudo cargar Google Maps'));
    document.head.appendChild(s);
  });
  return promesa;
}

export function useGoogleMaps() {
  const [state, setState] = useState({
    loaded: !!window.google?.maps,
    error: false,
  });

  useEffect(() => {
    let activo = true;
    cargarScript()
      .then(() => activo && setState({ loaded: true, error: false }))
      .catch(() => activo && setState({ loaded: false, error: true }));
    return () => {
      activo = false;
    };
  }, []);

  return state;
}

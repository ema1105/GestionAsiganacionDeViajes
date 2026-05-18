import { useEffect, useRef } from 'react';
import { useGoogleMaps } from '../../hooks/useGoogleMaps.js';
import Spinner from '../ui/Spinner.jsx';
import { IconPin } from '../icons/Icons.jsx';

// Estilo oscuro premium coherente con la identidad GAV.
const DARK_STYLE = [
  { elementType: 'geometry', stylers: [{ color: '#0d0d0d' }] },
  { elementType: 'labels.text.stroke', stylers: [{ color: '#0d0d0d' }] },
  { elementType: 'labels.text.fill', stylers: [{ color: '#5C5247' }] },
  {
    featureType: 'road',
    elementType: 'geometry',
    stylers: [{ color: '#1E1A16' }],
  },
  {
    featureType: 'road',
    elementType: 'geometry.stroke',
    stylers: [{ color: '#2A2520' }],
  },
  {
    featureType: 'water',
    elementType: 'geometry',
    stylers: [{ color: '#0A0A0A' }],
  },
  { featureType: 'poi', elementType: 'labels', stylers: [{ visibility: 'off' }] },
  { featureType: 'transit', stylers: [{ visibility: 'off' }] },
  {
    featureType: 'administrative',
    elementType: 'geometry',
    stylers: [{ color: '#2A2520' }],
  },
];

const COLORS = {
  origen: '#C9A96E',
  destino: '#38bdf8',
  conductor: '#C9A96E',
};

function dot(color, ring = false) {
  return {
    path: window.google.maps.SymbolPath.CIRCLE,
    scale: ring ? 8 : 7,
    fillColor: color,
    fillOpacity: ring ? 0.9 : 0.6,
    strokeColor: color,
    strokeWeight: 2,
  };
}

// Límites geográficos de Cartagena de Indias y corregimientos aledaños.
// Se usan tanto para restringir el mapa como para validar puntos en el padre.
export const CARTAGENA_BOUNDS = {
  north: 10.54,
  south: 10.26,
  east:  -75.46,
  west:  -75.66,
};

// Mapa reutilizable. Soporta modo lectura y modo interactivo:
//  - onMapClick(latLng): click en el mapa devuelve coordenadas
//  - markers[].draggable + onMarkerDragEnd(kind, latLng): pin arrastrable
//  - restrictToCartagena: bloquea el paneo fuera del área de Cartagena
// Fallback elegante si no hay clave o falla la carga (la vista no se rompe).
export default function MapView({
  center = { lat: 10.4236, lng: -75.5512 },
  zoom = 13,
  markers = [],
  className = '',
  onMapClick,
  onMarkerDragEnd,
  restrictToCartagena = false,
}) {
  const { loaded, error } = useGoogleMaps();
  const divRef = useRef(null);
  const mapRef = useRef(null);
  const overlaysRef = useRef([]);
  const clickCbRef = useRef(onMapClick);
  const dragCbRef = useRef(onMarkerDragEnd);

  // Mantiene las callbacks frescas sin re-crear el mapa.
  clickCbRef.current = onMapClick;
  dragCbRef.current = onMarkerDragEnd;

  useEffect(() => {
    if (!loaded || !divRef.current || mapRef.current) return;
    const mapOptions = {
      center,
      zoom,
      disableDefaultUI: true,
      styles: DARK_STYLE,
      backgroundColor: '#0d0d0d',
      draggableCursor: clickCbRef.current ? 'crosshair' : undefined,
    };
    if (restrictToCartagena) {
      mapOptions.restriction = {
        latLngBounds: CARTAGENA_BOUNDS,
        strictBounds: false,
      };
    }
    const map = new window.google.maps.Map(divRef.current, mapOptions);
    map.addListener('click', (e) => {
      clickCbRef.current?.({ lat: e.latLng.lat(), lng: e.latLng.lng() });
    });
    mapRef.current = map;
  }, [loaded]); // eslint-disable-line react-hooks/exhaustive-deps

  // Re-dibuja marcadores y ruta cuando cambian.
  useEffect(() => {
    const map = mapRef.current;
    if (!loaded || !map) return;

    let cancelled = false;
    let routeLine = null;

    overlaysRef.current.forEach((o) => o.setMap(null));
    overlaysRef.current = [];

    const pts = [];
    markers.forEach((m) => {
      if (m.lat == null || m.lng == null) return;
      const pos = { lat: Number(m.lat), lng: Number(m.lng) };
      pts.push(pos);
      const mk = new window.google.maps.Marker({
        position: pos,
        map,
        title: m.title ?? '',
        draggable: !!m.draggable,
        icon: dot(COLORS[m.kind] ?? '#C9A96E', m.kind === 'conductor'),
      });
      if (m.draggable) {
        mk.addListener('dragend', (e) => {
          dragCbRef.current?.(m.kind, {
            lat: e.latLng.lat(),
            lng: e.latLng.lng(),
          });
        });
      }
      overlaysRef.current.push(mk);
    });

    const o = markers.find((m) => m.kind === 'origen');
    const d = markers.find((m) => m.kind === 'destino');

    // Dibuja una línea recta (fallback si el ruteo real no está disponible).
    const dibujarRecta = () => {
      if (cancelled || !o || !d || o.lat == null || d.lat == null) return;
      routeLine = new window.google.maps.Polyline({
        path: [
          { lat: Number(o.lat), lng: Number(o.lng) },
          { lat: Number(d.lat), lng: Number(d.lng) },
        ],
        map,
        strokeColor: '#C9A96E',
        strokeOpacity: 0.45,
        strokeWeight: 2,
      });
      overlaysRef.current.push(routeLine);
    };

    if (o && d && o.lat != null && d.lat != null) {
      // Ruteo real: la línea sigue calles y vías (Directions API).
      const ds = new window.google.maps.DirectionsService();
      ds.route(
        {
          origin: { lat: Number(o.lat), lng: Number(o.lng) },
          destination: { lat: Number(d.lat), lng: Number(d.lng) },
          travelMode: window.google.maps.TravelMode.DRIVING,
        },
        (result, status) => {
          if (cancelled) return;
          if (status === 'OK' && result?.routes?.[0]?.overview_path) {
            routeLine = new window.google.maps.Polyline({
              path: result.routes[0].overview_path,
              map,
              strokeColor: '#C9A96E',
              strokeOpacity: 0.85,
              strokeWeight: 4,
            });
            overlaysRef.current.push(routeLine);
          } else {
            // Directions API no habilitada o sin ruta: fallback recto.
            dibujarRecta();
          }
        }
      );
    }

    const conductor = markers.find((m) => m.kind === 'conductor');
    if (conductor && conductor.lat != null) {
      map.panTo({ lat: Number(conductor.lat), lng: Number(conductor.lng) });
    } else if (pts.length === 1) {
      map.panTo(pts[0]);
    } else if (pts.length > 1) {
      const b = new window.google.maps.LatLngBounds();
      pts.forEach((p) => b.extend(p));
      map.fitBounds(b, 80);
    }

    return () => {
      cancelled = true;
      if (routeLine) routeLine.setMap(null);
    };
  }, [loaded, markers]);

  if (error) {
    return (
      <div
        className={`relative overflow-hidden rounded-xl border border-line ${className}`}
      >
        <div
          className="grid-pattern absolute inset-0 opacity-30"
          style={{ background: '#0A0A0A' }}
        />
        <div className="relative flex h-full min-h-[320px] flex-col items-center justify-center gap-2 text-gold">
          <IconPin width={36} height={36} />
          <span className="text-xs uppercase tracking-wider text-muted">
            Mapa no disponible
          </span>
        </div>
      </div>
    );
  }

  return (
    <div
      className={`relative overflow-hidden rounded-xl border border-line ${className}`}
    >
      {!loaded && (
        <div className="absolute inset-0 z-10 flex items-center justify-center bg-panel">
          <Spinner size="h-8 w-8" />
        </div>
      )}
      <div ref={divRef} className="h-full min-h-[320px] w-full" />
    </div>
  );
}

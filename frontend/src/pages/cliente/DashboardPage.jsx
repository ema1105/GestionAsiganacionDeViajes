import { useState, useCallback, useEffect } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Button from '../../components/ui/Button.jsx';
import MapView, { CARTAGENA_BOUNDS } from '../../components/map/MapView.jsx';
import { reverseGeocode } from '../../components/map/geocode.js';
import { IconPin } from '../../components/icons/Icons.jsx';
import { clienteApi } from '../../api/cliente.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const TIPOS = [
  { key: 'CONFORT', label: 'Confort', mult: 1,   maxPax: 4 },
  { key: 'PREMIUM', label: 'Premium', mult: 1.6, maxPax: 4 },
  { key: 'XL',      label: 'XL',      mult: 2,   maxPax: 6 },
];

// Valida que las coordenadas estén dentro del área de Cartagena.
const dentroDeCartagena = (lat, lng) =>
  lat >= CARTAGENA_BOUNDS.south &&
  lat <= CARTAGENA_BOUNDS.north &&
  lng >= CARTAGENA_BOUNDS.west  &&
  lng <= CARTAGENA_BOUNDS.east;

// Puntos de referencia conocidos de Cartagena de Indias.
// El cliente piensa en lugares, no en coordenadas.
const REFERENCIAS = [
  { nombre: 'Centro Histórico (Ciudad Amurallada)', lat: 10.4236, lng: -75.5510 },
  { nombre: 'Castillo San Felipe de Barajas', lat: 10.4226, lng: -75.5390 },
  { nombre: 'Torre del Reloj', lat: 10.4225, lng: -75.5510 },
  { nombre: 'Playa de Bocagrande', lat: 10.4000, lng: -75.5550 },
  { nombre: 'Aeropuerto Rafael Núñez', lat: 10.4424, lng: -75.5130 },
  { nombre: 'Getsemaní', lat: 10.4200, lng: -75.5450 },
  { nombre: 'C.C. Caribe Plaza', lat: 10.4090, lng: -75.5360 },
  { nombre: 'C.C. La Serrezuela', lat: 10.4257, lng: -75.5494 },
  { nombre: 'Castillogrande', lat: 10.3950, lng: -75.5600 },
];

const fmtMoney = (n) =>
  new Intl.NumberFormat('es-CO', {
    style: 'currency',
    currency: 'COP',
    maximumFractionDigits: 0,
  }).format(n || 0);

export default function ClienteDashboardPage() {
  const toast = useToast();
  const [tipo, setTipo] = useState('CONFORT');
  const [pasajeros, setPasajeros] = useState(1);
  const [origen, setOrigen] = useState(null); // { lat, lng, label }
  const [destino, setDestino] = useState(null);
  const [modo, setModo] = useState('origen'); // qué punto define el próximo clic
  const [loading, setLoading] = useState(false);

  // Selección automática de vehículo según pasajeros:
  //   ≥ 5 → solo XL puede acomodar el grupo; se fuerza y se bloquean los demás.
  //   < 5 → si estaba en XL forzado, vuelve a Confort.
  useEffect(() => {
    if (pasajeros >= 5) {
      setTipo('XL');
    } else if (pasajeros < 5 && tipo === 'XL') {
      // Solo revertir si el tipo era XL para no pisar una elección explícita
      // del usuario cuando baja el número de pasajeros.
      setTipo('CONFORT');
    }
  }, [pasajeros]); // eslint-disable-line react-hooks/exhaustive-deps

  // Coloca un punto y resuelve su dirección legible (best-effort).
  const fijarPunto = useCallback(
    async (cual, lat, lng, etiqueta) => {
      const set = cual === 'origen' ? setOrigen : setDestino;
      set({ lat, lng, label: etiqueta ?? 'Buscando dirección…' });
      if (!etiqueta) {
        const dir = await reverseGeocode(lat, lng);
        set({ lat, lng, label: dir ?? 'Punto seleccionado en el mapa' });
      }
      // Tras fijar el origen, el siguiente clic define el destino.
      if (cual === 'origen') setModo('destino');
    },
    []
  );

  const onMapClick = useCallback(
    ({ lat, lng }) => {
      if (!dentroDeCartagena(lat, lng)) {
        toast.error(
          'Solo se permiten destinos dentro de Cartagena de Indias y sus corregimientos'
        );
        return;
      }
      fijarPunto(modo, lat, lng);
    },
    [modo, fijarPunto, toast]
  );

  const onMarkerDragEnd = useCallback(
    (kind, { lat, lng }) => fijarPunto(kind, lat, lng),
    [fijarPunto]
  );

  const elegirReferencia = (e) => {
    const r = REFERENCIAS[e.target.value];
    if (!r) return;
    fijarPunto(modo, r.lat, r.lng, r.nombre);
  };

  // Estimación visual (haversine simplificado) sólo si hay ambos puntos.
  const distKm =
    origen && destino
      ? Math.max(
          1,
          Math.round(
            Math.sqrt(
              (destino.lat - origen.lat) ** 2 +
                (destino.lng - origen.lng) ** 2
            ) * 111
          )
        )
      : 0;
  const mult = TIPOS.find((t) => t.key === tipo)?.mult ?? 1;
  const precioEstimado = distKm
    ? Math.round((4000 + distKm * 2200) * mult)
    : 0;

  const solicitar = async () => {
    if (!origen || !destino) {
      toast.error('Selecciona origen y destino en el mapa');
      return;
    }
    setLoading(true);
    try {
      await clienteApi.solicitarViaje({
        origenLat: origen.lat,
        origenLng: origen.lng,
        destinoLat: destino.lat,
        destinoLng: destino.lng,
        cantidadPasajeros: Number(pasajeros),
        distanciaKm: distKm,
        duracionMin: distKm * 3,
      });
      toast.success('Viaje solicitado. Buscando conductor...');
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo solicitar el viaje');
    } finally {
      setLoading(false);
    }
  };

  const Campo = ({ tipoCampo, punto, etiqueta }) => {
    const activo = modo === tipoCampo;
    const color = tipoCampo === 'origen' ? 'text-gold' : 'text-sky-400';
    return (
      <button
        type="button"
        onClick={() => setModo(tipoCampo)}
        className={`w-full rounded-lg border px-4 py-3 text-left transition-all duration-200 ${
          activo
            ? 'border-gold/60 bg-gold/5'
            : 'border-line hover:border-line-soft'
        }`}
      >
        <div className="flex items-center gap-2">
          <IconPin width={16} height={16} className={color} />
          <span className="label-premium">{etiqueta}</span>
          {activo && (
            <span className="ml-auto text-[10px] uppercase tracking-wider text-gold">
              Seleccionando
            </span>
          )}
        </div>
        <p
          className={`mt-1.5 truncate text-sm ${
            punto ? 'text-ink' : 'text-muted'
          }`}
        >
          {punto ? punto.label : 'Toca el mapa o elige un lugar'}
        </p>
      </button>
    );
  };

  const markers = [
    origen && {
      lat: origen.lat,
      lng: origen.lng,
      kind: 'origen',
      title: 'Origen',
      draggable: true,
    },
    destino && {
      lat: destino.lat,
      lng: destino.lng,
      kind: 'destino',
      title: 'Destino',
      draggable: true,
    },
  ].filter(Boolean);

  return (
    <div>
      <PageHeader
        title="Solicitar Viaje"
        subtitle="Marca en el mapa dónde estás y a dónde quieres ir"
      />

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        {/* Panel izquierdo */}
        <Card className="p-6">
          <div className="flex flex-col gap-4">
            <Campo tipoCampo="origen" punto={origen} etiqueta="Origen — aquí estoy" />
            <Campo
              tipoCampo="destino"
              punto={destino}
              etiqueta="Destino — aquí quiero ir"
            />

            <div>
              <p className="label-premium mb-2">
                ¿No conoces la ubicación exacta? Elige un lugar
              </p>
              <select
                onChange={elegirReferencia}
                value=""
                className="w-full rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink outline-none focus:border-gold/60"
              >
                <option value="" className="bg-surface">
                  Puntos de referencia conocidos…
                </option>
                {REFERENCIAS.map((r, i) => (
                  <option key={r.nombre} value={i} className="bg-surface">
                    {r.nombre}
                  </option>
                ))}
              </select>
              <p className="mt-1.5 text-[11px] text-muted">
                Se asigna al campo «{modo === 'origen' ? 'Origen' : 'Destino'}»
              </p>
            </div>

            <div>
              <p className="label-premium mb-2">Pasajeros</p>
              <div className="flex gap-2">
                {[1, 2, 3, 4, 5, 6].map((n) => (
                  <button
                    key={n}
                    onClick={() => setPasajeros(n)}
                    className={`h-10 w-10 rounded-lg border text-sm transition-all duration-200 ${
                      pasajeros === n
                        ? 'border-gold/60 bg-gold/10 text-gold'
                        : 'border-line text-muted hover:text-subtle'
                    }`}
                  >
                    {n}
                  </button>
                ))}
              </div>
            </div>

            <div>
              <p className="label-premium mb-2">Tipo de vehículo</p>
              {pasajeros >= 5 && (
                <p className="mb-2 text-[11px] text-gold/80">
                  Con 5 o más pasajeros solo está disponible XL
                </p>
              )}
              <div className="grid grid-cols-3 gap-3">
                {TIPOS.map((t) => {
                  const forzado = pasajeros >= 5 && t.key !== 'XL';
                  return (
                    <button
                      key={t.key}
                      onClick={() => !forzado && setTipo(t.key)}
                      disabled={forzado}
                      title={forzado ? 'No disponible para 5 o más pasajeros' : ''}
                      className={`rounded-lg border py-3 text-sm font-medium transition-all duration-200 ${
                        tipo === t.key
                          ? 'border-gold/60 bg-gold/10 text-gold'
                          : forzado
                          ? 'cursor-not-allowed border-line/30 text-muted/30'
                          : 'border-line text-muted hover:text-subtle'
                      }`}
                    >
                      <span>{t.label}</span>
                      {forzado && (
                        <span className="block text-[9px] text-muted/40 mt-0.5">
                          No disponible
                        </span>
                      )}
                    </button>
                  );
                })}
              </div>
            </div>

            <Button
              variant="gold"
              loading={loading}
              onClick={solicitar}
              disabled={!origen || !destino}
              className="mt-2 w-full"
            >
              {origen && destino
                ? 'Confirmar solicitud'
                : 'Selecciona origen y destino'}
            </Button>
          </div>
        </Card>

        {/* Panel derecho — mapa interactivo */}
        <div className="relative">
          <MapView
            className="h-full min-h-[460px]"
            onMapClick={onMapClick}
            onMarkerDragEnd={onMarkerDragEnd}
            markers={markers}
            restrictToCartagena
          />
          {origen && destino && (
            <div className="absolute bottom-5 left-5 right-5 z-10 rounded-xl border border-line bg-surface/95 p-5 backdrop-blur">
              <p className="text-[11px] uppercase tracking-wider text-muted">
                Precio estimado
              </p>
              <div className="mt-1 flex items-end justify-between">
                <span className="font-serif text-3xl text-ink">
                  {fmtMoney(precioEstimado)}
                </span>
                <span className="text-xs text-muted">
                  ≈ {distKm} km · {TIPOS.find((t) => t.key === tipo)?.label}
                </span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

import { useEffect, useState, useCallback, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Button from '../../components/ui/Button.jsx';
import Badge, { estadoViajeTone } from '../../components/ui/Badge.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import MapView from '../../components/map/MapView.jsx';
import { clienteApi } from '../../api/cliente.api.js';

// Flujo completo del viaje, desde la solicitud hasta la finalización.
// El timeline visualiza el progreso y resalta el estado actual.
const ESTADOS_FLUJO = [
  'SOLICITADO',
  'BUSCANDO_CONDUCTOR',
  'ACEPTADO',
  'EN_CAMINO',
  'EN_CURSO',
  'FINALIZADO',
];

const ESTADOS_TERMINALES = ['FINALIZADO', 'CANCELADO'];

// Etiquetas legibles para mostrar el estado al cliente.
const ETIQUETA_ESTADO = {
  SOLICITADO: 'Solicitado',
  BUSCANDO_CONDUCTOR: 'Buscando conductor',
  ACEPTADO: 'Conductor asignado',
  EN_CAMINO: 'Conductor en camino',
  EN_CURSO: 'Viaje en curso',
  FINALIZADO: 'Finalizado',
  CANCELADO: 'Cancelado',
};

export default function SeguimientoPage() {
  const navigate = useNavigate();
  const [loading, setLoading] = useState(true);
  const [viaje, setViaje] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [pos, setPos] = useState(null);
  const [updated, setUpdated] = useState(null);
  // Conserva el último id conocido para hacer fallback cuando viaje-activo
  // deja de devolverlo (porque pasó a CANCELADO / FINALIZADO).
  const lastIdRef = useRef(null);

  const refrescar = useCallback(async () => {
    // 1) Intento normal: viaje activo (todo lo que NO es FINALIZADO/CANCELADO).
    const v = await clienteApi.viajeActivo();

    let viajeActual = v;

    // 2) Fallback: si ya no hay activo PERO conocíamos un id, traemos su detalle
    //    para poder mostrar el estado final (CANCELADO o FINALIZADO).
    if (!viajeActual && lastIdRef.current) {
      const d = await clienteApi.detalleViaje(lastIdRef.current);
      if (d?.id) {
        viajeActual = d;       // detalle ya incluye los mismos campos básicos
        setDetalle(d);
      }
    }

    setViaje(viajeActual);

    if (viajeActual?.id) {
      lastIdRef.current = viajeActual.id;

      // Detalle expandido (conductor + vehículo). Si el viaje sigue activo,
      // lo refrescamos. Si veníamos del fallback, ya está seteado arriba.
      if (!ESTADOS_TERMINALES.includes(viajeActual.estadoViaje)) {
        const d = await clienteApi.detalleViaje(viajeActual.id);
        if (d) setDetalle(d);

        const ult = await clienteApi.seguimientoUltima(viajeActual.id);
        if (ult?.lat != null && ult?.lng != null) {
          setPos({ lat: ult.lat, lng: ult.lng });
          setUpdated(ult.fecha ?? new Date().toISOString());
        } else if (viajeActual.origenLat != null) {
          setPos({ lat: viajeActual.origenLat, lng: viajeActual.origenLng });
        }
      }
    }

    setLoading(false);
  }, []);

  useEffect(() => {
    refrescar();
    // Polling cada 6s para reflejar transiciones de estado en tiempo real
    // (SOLICITADO → BUSCANDO_CONDUCTOR → ACEPTADO → EN_CAMINO → EN_CURSO → FINALIZADO,
    // o un CANCELADO en cualquier paso anterior a EN_CURSO).
    const id = setInterval(refrescar, 6000);
    return () => clearInterval(id);
  }, [refrescar]);

  if (loading) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <Spinner size="h-8 w-8" />
      </div>
    );
  }

  if (!viaje) {
    return (
      <div>
        <PageHeader
          title="Seguimiento"
          subtitle="Ubicación en tiempo real de tu viaje"
        />
        <Card className="flex h-64 flex-col items-center justify-center gap-3 text-center">
          <p className="font-serif text-2xl text-ink">Sin viaje activo</p>
          <p className="text-sm text-muted">
            Solicita un viaje para ver el seguimiento en vivo.
          </p>
          <Button variant="gold" onClick={() => navigate('/cliente')}>
            Solicitar un viaje
          </Button>
        </Card>
      </div>
    );
  }

  const estado = viaje.estadoViaje;
  const esTerminal = ESTADOS_TERMINALES.includes(estado);
  const esCancelado = estado === 'CANCELADO';
  const idxEstado = ESTADOS_FLUJO.indexOf(estado);

  return (
    <div>
      <PageHeader
        title="Seguimiento"
        subtitle={`Viaje #${viaje.id} · ${ETIQUETA_ESTADO[estado] ?? estado}`}
      />

      {/* Banner especial para estados terminales — refuerza el feedback visual */}
      {esTerminal && (
        <Card
          className={`mb-6 border-2 p-5 ${
            esCancelado
              ? 'border-red-500/40 bg-red-500/5'
              : 'border-emerald-500/40 bg-emerald-500/5'
          }`}
        >
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <p className={`font-serif text-xl ${esCancelado ? 'text-red-400' : 'text-emerald-400'}`}>
                {esCancelado ? 'Viaje cancelado' : '¡Viaje completado!'}
              </p>
              <p className="mt-1 text-sm text-muted">
                {esCancelado
                  ? 'Tu viaje fue cancelado. Puedes solicitar uno nuevo cuando quieras.'
                  : 'Gracias por viajar con GAV. No olvides calificar al conductor.'}
              </p>
            </div>
            <Button variant="gold" onClick={() => navigate('/cliente')}>
              Solicitar un nuevo viaje
            </Button>
          </div>
        </Card>
      )}

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Mapa real */}
        <div className="relative lg:col-span-2">
          <MapView
            className="h-full min-h-[420px]"
            center={
              pos ??
              (viaje.origenLat != null
                ? { lat: viaje.origenLat, lng: viaje.origenLng }
                : undefined)
            }
            markers={[
              viaje.origenLat != null && {
                lat: viaje.origenLat,
                lng: viaje.origenLng,
                kind: 'origen',
                title: 'Origen',
              },
              viaje.destinoLat != null && {
                lat: viaje.destinoLat,
                lng: viaje.destinoLng,
                kind: 'destino',
                title: 'Destino',
              },
              pos && !esTerminal && {
                lat: pos.lat,
                lng: pos.lng,
                kind: 'conductor',
                title: 'Conductor',
              },
            ].filter(Boolean)}
          />
          <div className="absolute bottom-4 left-4 z-10 rounded-lg border border-line bg-surface/95 px-3 py-2 text-xs text-muted backdrop-blur">
            {esTerminal
              ? `Viaje ${ETIQUETA_ESTADO[estado]?.toLowerCase() ?? 'cerrado'}`
              : updated
              ? `Última actualización: ${new Date(updated).toLocaleTimeString('es-CO')}`
              : 'Esperando señal GPS del conductor…'}
          </div>
        </div>

        {/* Panel lateral */}
        <div className="flex flex-col gap-6">
          <Card className="p-6">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="font-serif text-xl text-ink">Estado</h3>
              <Badge tone={estadoViajeTone(estado)}>
                {ETIQUETA_ESTADO[estado] ?? estado}
              </Badge>
            </div>

            {/* Timeline del flujo. Si fue CANCELADO se muestra un aviso separado. */}
            {esCancelado ? (
              <div className="rounded-lg border border-red-500/30 bg-red-500/5 p-4">
                <p className="text-sm font-medium text-red-400">
                  El viaje fue cancelado
                </p>
                <p className="mt-1 text-xs text-muted">
                  No se realizará el servicio. Puedes solicitar otro viaje cuando lo necesites.
                </p>
              </div>
            ) : (
              <div className="relative pl-6">
                <div className="absolute left-[5px] top-1 bottom-1 w-px bg-line" />
                {ESTADOS_FLUJO.map((e, i) => (
                  <div key={e} className="relative mb-3 last:mb-0">
                    <span
                      className={`absolute -left-[23px] top-0.5 h-3 w-3 rounded-full border-2 ${
                        i <= idxEstado
                          ? 'border-gold bg-gold/40'
                          : 'border-line bg-surface'
                      }`}
                    />
                    <span
                      className={`text-sm ${
                        i <= idxEstado ? 'text-ink' : 'text-muted'
                      }`}
                    >
                      {ETIQUETA_ESTADO[e] ?? e}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </Card>

          <Card className="p-6">
            <h3 className="mb-3 font-serif text-xl text-ink">Conductor</h3>
            {detalle?.conductorNombre ? (
              <div className="space-y-1.5 text-sm">
                <p className="text-ink">
                  {detalle.conductorNombre}{' '}
                  {detalle.conductorApellidos ?? ''}
                </p>
                <p className="text-muted">
                  Tel: {detalle.conductorTelefono ?? '—'}
                </p>
                <p className="text-muted">
                  {detalle.vehiculoMarca ?? ''} {detalle.vehiculoModelo ?? ''}{' '}
                  {detalle.vehiculoPlaca ? `· ${detalle.vehiculoPlaca}` : ''}
                </p>
                <p className="text-muted">
                  {detalle.vehiculoCategoria ?? ''}
                </p>
              </div>
            ) : (
              <p className="text-sm text-muted">
                {estado === 'SOLICITADO' || estado === 'BUSCANDO_CONDUCTOR'
                  ? 'Buscando un conductor disponible…'
                  : 'Aún no hay un conductor asignado.'}
              </p>
            )}
          </Card>
        </div>
      </div>
    </div>
  );
}

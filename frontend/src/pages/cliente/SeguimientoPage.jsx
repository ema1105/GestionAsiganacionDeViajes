import { useEffect, useState, useCallback } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Badge, { estadoViajeTone } from '../../components/ui/Badge.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import MapView from '../../components/map/MapView.jsx';
import { clienteApi } from '../../api/cliente.api.js';

const ESTADOS_FLUJO = [
  'ACEPTADO',
  'EN_CAMINO',
  'EN_CURSO',
  'FINALIZADO',
];

export default function SeguimientoPage() {
  const [loading, setLoading] = useState(true);
  const [viaje, setViaje] = useState(null);
  const [detalle, setDetalle] = useState(null);
  const [pos, setPos] = useState(null);
  const [updated, setUpdated] = useState(null);

  const refrescar = useCallback(async () => {
    const v = await clienteApi.viajeActivo();
    setViaje(v);
    if (v?.id) {
      const [d, ult] = await Promise.all([
        clienteApi.detalleViaje(v.id),
        clienteApi.seguimientoUltima(v.id),
      ]);
      setDetalle(d);
      if (ult?.lat != null && ult?.lng != null) {
        setPos({ lat: ult.lat, lng: ult.lng });
        setUpdated(ult.fecha ?? new Date().toISOString());
      } else if (v.origenLat != null) {
        setPos({ lat: v.origenLat, lng: v.origenLng });
      }
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    refrescar();
    const id = setInterval(refrescar, 6000); // polling en tiempo real
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
        <Card className="flex h-64 flex-col items-center justify-center gap-2 text-center">
          <p className="font-serif text-2xl text-ink">Sin viaje activo</p>
          <p className="text-sm text-muted">
            Solicita un viaje para ver el seguimiento en vivo.
          </p>
        </Card>
      </div>
    );
  }

  const idxEstado = ESTADOS_FLUJO.indexOf(viaje.estadoViaje);

  return (
    <div>
      <PageHeader
        title="Seguimiento"
        subtitle={`Viaje #${viaje.id} en tiempo real`}
      />

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
              pos && {
                lat: pos.lat,
                lng: pos.lng,
                kind: 'conductor',
                title: 'Conductor',
              },
            ].filter(Boolean)}
          />
          <div className="absolute bottom-4 left-4 z-10 rounded-lg border border-line bg-surface/95 px-3 py-2 text-xs text-muted backdrop-blur">
            {updated
              ? `Última actualización: ${new Date(
                  updated
                ).toLocaleTimeString('es-CO')}`
              : 'Esperando señal GPS del conductor…'}
          </div>
        </div>

        {/* Panel lateral */}
        <div className="flex flex-col gap-6">
          <Card className="p-6">
            <div className="mb-4 flex items-center justify-between">
              <h3 className="font-serif text-xl text-ink">Estado</h3>
              <Badge tone={estadoViajeTone(viaje.estadoViaje)}>
                {viaje.estadoViaje}
              </Badge>
            </div>
            <div className="relative pl-6">
              <div className="absolute left-[5px] top-1 bottom-1 w-px bg-line" />
              {ESTADOS_FLUJO.map((e, i) => (
                <div key={e} className="relative mb-4 last:mb-0">
                  <span
                    className={`absolute -left-[23px] top-0.5 h-3 w-3 rounded-full border-2 ${
                      i <= idxEstado
                        ? 'border-gold bg-gold/40'
                        : 'border-line bg-surface'
                    }`}
                  />
                  <span
                    className={
                      i <= idxEstado ? 'text-ink' : 'text-muted'
                    }
                  >
                    {e}
                  </span>
                </div>
              ))}
            </div>
          </Card>

          <Card className="p-6">
            <h3 className="mb-3 font-serif text-xl text-ink">Conductor</h3>
            {detalle ? (
              <div className="space-y-1.5 text-sm">
                <p className="text-ink">
                  {detalle.conductorNombre ?? 'Asignando…'}{' '}
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
                Aún no hay un conductor asignado.
              </p>
            )}
          </Card>
        </div>
      </div>
    </div>
  );
}

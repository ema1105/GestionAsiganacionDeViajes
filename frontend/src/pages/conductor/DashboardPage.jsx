import { useEffect, useState, useCallback, useRef } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Button from '../../components/ui/Button.jsx';
import Badge, { estadoViajeTone } from '../../components/ui/Badge.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import Modal from '../../components/ui/Modal.jsx';
import MapView from '../../components/map/MapView.jsx';
import { IconStar } from '../../components/icons/Icons.jsx';
import { conductorApi } from '../../api/conductor.api.js';
import { useToast } from '../../context/ToastContext.jsx';
import { useRoleGate } from '../../hooks/useRoleGate.js';
import { ROLES } from '../../constants/roles.js';

// Cuánto tiempo (ms) mantenemos visible el aviso "viaje cancelado por el cliente"
// antes de limpiarlo automáticamente del panel del conductor.
const AVISO_CANCEL_MS = 15_000;

export default function ConductorDashboardPage() {
  const toast = useToast();
  // Defensa en profundidad: ningún request de conductor se dispara si el
  // rol autenticado no es CONDUCTOR (evita 403 de admin/cliente).
  const { authorized } = useRoleGate(ROLES.CONDUCTOR);
  const [loading, setLoading] = useState(true);
  const [activo, setActivo] = useState(null);
  const [pendiente, setPendiente] = useState(null);
  const [busy, setBusy] = useState(false);
  const [calificar, setCalificar] = useState(null); // viajeId a calificar
  const [vehiculo, setVehiculo] = useState(null);   // datos del vehículo asignado
  // Aviso temporal cuando el cliente cancela un viaje activo.
  const [cancelado, setCancelado] = useState(null); // { viajeId } | null
  // Referencia al último viaje activo conocido para detectar cancelaciones.
  const activoPrevRef = useRef(null);
  const avisoTimerRef = useRef(null);

  // Carga los datos del vehículo asignado una sola vez al montar.
  useEffect(() => {
    if (!authorized) return;
    conductorApi
      .obtenerPerfil()
      .then((p) => {
        if (p?.marcaVehiculo) {
          setVehiculo({
            marca:      p.marcaVehiculo,
            modelo:     p.modeloVehiculo,
            placa:      p.placaVehiculo,
            capacidad:  p.capacidadMaxima,
            categoria:  p.categoriaVehiculo,
          });
        }
      })
      .catch(() => {});
  }, [authorized]);

  // Muestra un aviso temporal cuando el cliente cancela un viaje en curso
  // y dispara un toast inmediato. El aviso se limpia tras AVISO_CANCEL_MS.
  const mostrarCancelacion = useCallback((viajeId) => {
    setCancelado({ viajeId });
    toast.error(`El cliente canceló el viaje #${viajeId}`);
    if (avisoTimerRef.current) clearTimeout(avisoTimerRef.current);
    avisoTimerRef.current = setTimeout(
      () => setCancelado(null),
      AVISO_CANCEL_MS
    );
  }, [toast]);

  const refrescar = useCallback(async () => {
    const [a, p] = await Promise.all([
      conductorApi.viajeActivo(),
      conductorApi.solicitudPendiente(),
    ]);

    // Detección de cancelación por cliente:
    // si teníamos un viaje activo y ahora /viaje-activo no devuelve nada,
    // consultamos su detalle para saber si pasó a CANCELADO.
    const prev = activoPrevRef.current;
    if (prev && !a && prev.id) {
      const detalle = await conductorApi.detalleViaje(prev.id);
      if (detalle?.estadoViaje === 'CANCELADO') {
        mostrarCancelacion(prev.id);
      }
    }
    activoPrevRef.current = a;

    setActivo(a);
    setPendiente(p);
    setLoading(false);
  }, [mostrarCancelacion]);

  // Limpieza del timer al desmontar.
  useEffect(() => {
    return () => {
      if (avisoTimerRef.current) clearTimeout(avisoTimerRef.current);
    };
  }, []);

  useEffect(() => {
    // No dispara requests ni polling si el rol no es CONDUCTOR.
    if (!authorized) return;
    refrescar();
    // Polling cada 6s para nuevas solicitudes y cambios de estado.
    const id = setInterval(refrescar, 6000);
    return () => clearInterval(id);
  }, [authorized, refrescar]);

  const responder = async (aceptar) => {
    setBusy(true);
    try {
      await conductorApi.responder(pendiente.viajeId ?? pendiente.id, aceptar);
      toast.success(aceptar ? 'Viaje aceptado' : 'Solicitud rechazada');
      await refrescar();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo responder');
    } finally {
      setBusy(false);
    }
  };

  const accion = async (fn, msg) => {
    setBusy(true);
    try {
      await fn(activo.id);
      toast.success(msg);
      await refrescar();
    } catch (e) {
      toast.error(e.mensaje || 'Acción fallida');
    } finally {
      setBusy(false);
    }
  };

  // Cierre del servicio: finaliza el viaje y abre la calificación del cliente.
  const finalizarYCalificar = async () => {
    setBusy(true);
    try {
      const viajeId = activo.id;
      await conductorApi.finalizar(viajeId);
      toast.success('Viaje finalizado');
      setCalificar(viajeId);
      await refrescar();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo finalizar');
    } finally {
      setBusy(false);
    }
  };

  if (loading) {
    return (
      <div className="flex h-[60vh] items-center justify-center">
        <Spinner size="h-8 w-8" />
      </div>
    );
  }

  return (
    <div>
      <PageHeader
        title="Panel del Conductor"
        subtitle="Tu viaje activo y solicitudes entrantes"
      />

      {/* ── Tarjeta del vehículo asignado ── */}
      {vehiculo && (
        <Card className="mb-6 p-6">
          <p className="mb-4 text-[11px] uppercase tracking-wider text-muted">
            Vehículo asignado
          </p>
          <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
            <VehiculoDato etiqueta="Marca"     valor={vehiculo.marca} />
            <VehiculoDato etiqueta="Modelo"    valor={vehiculo.modelo} />
            <VehiculoDato
              etiqueta="Placa"
              valor={vehiculo.placa}
              highlight
            />
            <VehiculoDato
              etiqueta="Capacidad"
              valor={
                vehiculo.capacidad
                  ? `${vehiculo.capacidad} pasajeros`
                  : undefined
              }
            />
            <VehiculoDato etiqueta="Categoría" valor={vehiculo.categoria} />
          </div>
        </Card>
      )}

      {/* Aviso de cancelación reciente por parte del cliente.
          Refuerza el feedback visual aunque /viaje-activo ya devolvió null. */}
      {cancelado && (
        <Card className="mb-6 border-2 border-red-500/40 bg-red-500/5 p-5">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <Badge tone="red">Viaje cancelado</Badge>
              <p className="mt-2 text-ink">
                El cliente canceló el viaje #{cancelado.viajeId}.
              </p>
              <p className="text-sm text-muted">
                Vuelves al pool FIFO automáticamente. Espera la próxima solicitud.
              </p>
            </div>
            <Button variant="ghost" onClick={() => setCancelado(null)}>
              Ocultar
            </Button>
          </div>
        </Card>
      )}

      {/* Solicitud pendiente */}
      {pendiente && (
        <Card className="mb-6 border-gold/30 p-6">
          <div className="flex flex-wrap items-center justify-between gap-4">
            <div>
              <Badge tone="gold">Nueva solicitud</Badge>
              <p className="mt-2 text-ink">
                Viaje #{pendiente.viajeId ?? pendiente.id} ·{' '}
                {pendiente.cantidadPasajeros ?? 1} pasajero(s)
              </p>
              <p className="text-sm text-muted">
                Tienes unos segundos para responder
              </p>
            </div>
            <div className="flex gap-3">
              <Button
                variant="danger"
                disabled={busy}
                onClick={() => responder(false)}
              >
                Rechazar
              </Button>
              <Button
                variant="gold"
                loading={busy}
                onClick={() => responder(true)}
              >
                Aceptar viaje
              </Button>
            </div>
          </div>
        </Card>
      )}

      {/* Viaje activo */}
      {activo ? (
        <Card className="p-8">
          <div className="mb-6 flex items-center justify-between">
            <h3 className="font-serif text-2xl text-ink">
              Viaje #{activo.id}
            </h3>
            <Badge tone={estadoViajeTone(activo.estadoViaje)}>
              {activo.estadoViaje}
            </Badge>
          </div>

          {/* Mapa del trayecto */}
          {activo.origenLat != null && (
            <MapView
              className="mb-8 h-72"
              markers={[
                {
                  lat: activo.origenLat,
                  lng: activo.origenLng,
                  kind: 'origen',
                  title: 'Origen',
                },
                activo.destinoLat != null && {
                  lat: activo.destinoLat,
                  lng: activo.destinoLng,
                  kind: 'destino',
                  title: 'Destino',
                },
              ].filter(Boolean)}
            />
          )}

          {/* Timeline vertical */}
          <div className="relative pl-8">
            <div className="absolute left-[7px] top-2 bottom-2 w-px bg-line" />
            <div className="relative mb-8">
              <span className="absolute -left-[27px] top-1 h-3.5 w-3.5 rounded-full border-2 border-gold bg-gold/30" />
              <p className="text-[11px] uppercase tracking-wider text-muted">
                Origen
              </p>
              <p className="text-ink">
                {activo.origenLat?.toFixed?.(4)},{' '}
                {activo.origenLng?.toFixed?.(4)}
              </p>
            </div>
            <div className="relative">
              <span className="absolute -left-[27px] top-1 h-3.5 w-3.5 rounded-full border-2 border-sky-400 bg-sky-400/30" />
              <p className="text-[11px] uppercase tracking-wider text-muted">
                Destino
              </p>
              <p className="text-ink">
                {activo.destinoLat?.toFixed?.(4)},{' '}
                {activo.destinoLng?.toFixed?.(4)}
              </p>
            </div>
          </div>

          <div className="mt-8 border-t border-line pt-6">
            <p className="text-[11px] uppercase tracking-wider text-muted">
              Cliente
            </p>
            <p className="text-ink">
              {activo.clienteNombre ?? `Cliente ${activo.clienteId ?? '—'}`}
            </p>
          </div>

          <div className="mt-6 flex gap-3">
            {activo.estadoViaje === 'ACEPTADO' && (
              <Button
                onClick={() => accion(conductorApi.enCamino, 'En camino')}
                loading={busy}
              >
                Marcar en camino
              </Button>
            )}
            {(activo.estadoViaje === 'ACEPTADO' ||
              activo.estadoViaje === 'EN_CAMINO') && (
              <Button
                variant="gold"
                onClick={() => accion(conductorApi.iniciar, 'Viaje iniciado')}
                loading={busy}
              >
                Iniciar viaje
              </Button>
            )}
            {activo.estadoViaje === 'EN_CURSO' && (
              <Button
                variant="gold"
                onClick={finalizarYCalificar}
                loading={busy}
              >
                Finalizar viaje
              </Button>
            )}
          </div>
        </Card>
      ) : (
        !pendiente && (
          <Card className="flex h-64 flex-col items-center justify-center gap-2 text-center">
            <p className="font-serif text-2xl text-ink">Sin viaje activo</p>
            <p className="text-sm text-muted">
              Estás en la cola FIFO. Recibirás una solicitud pronto.
            </p>
          </Card>
        )
      )}

      <CalificarClienteModal
        viajeId={calificar}
        onClose={() => setCalificar(null)}
      />
    </div>
  );
}

// Celda de dato del vehículo con etiqueta superior.
function VehiculoDato({ etiqueta, valor, highlight = false }) {
  return (
    <div className="rounded-lg bg-surface/60 px-4 py-3">
      <p className="text-[10px] uppercase tracking-wider text-muted">{etiqueta}</p>
      <p
        className={`mt-1 text-sm font-medium ${
          highlight ? 'font-mono text-gold' : 'text-ink'
        }`}
      >
        {valor ?? '—'}
      </p>
    </div>
  );
}

function CalificarClienteModal({ viajeId, onClose }) {
  const toast = useToast();
  const [puntuacion, setPuntuacion] = useState(0);
  const [hover, setHover] = useState(0);
  const [comentario, setComentario] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setPuntuacion(0);
    setHover(0);
    setComentario('');
  }, [viajeId]);

  if (!viajeId) return null;

  const enviar = async () => {
    if (puntuacion < 1) {
      toast.error('Selecciona una puntuación');
      return;
    }
    setSaving(true);
    try {
      await conductorApi.calificarCliente(viajeId, {
        puntuacion,
        comentario,
      });
      toast.success('Cliente calificado. ¡Gracias!');
      onClose();
    } catch (e) {
      toast.error(e.mensaje || 'No se pudo enviar la calificación');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Modal
      open={!!viajeId}
      onClose={onClose}
      title={`Calificar al cliente · viaje #${viajeId}`}
      footer={
        <>
          <Button variant="ghost" onClick={onClose}>
            Omitir
          </Button>
          <Button onClick={enviar} loading={saving}>
            Enviar calificación
          </Button>
        </>
      }
    >
      <div className="flex flex-col items-center gap-5">
        <p className="text-sm text-muted">
          ¿Cómo fue tu experiencia con el cliente?
        </p>
        <div className="flex gap-2">
          {[1, 2, 3, 4, 5].map((i) => (
            <button
              key={i}
              type="button"
              onClick={() => setPuntuacion(i)}
              onMouseEnter={() => setHover(i)}
              onMouseLeave={() => setHover(0)}
              className="transition-transform duration-150 hover:scale-110"
              aria-label={`${i} estrellas`}
            >
              <IconStar
                filled={i <= (hover || puntuacion)}
                width={32}
                height={32}
              />
            </button>
          ))}
        </div>
        <textarea
          value={comentario}
          onChange={(e) => setComentario(e.target.value)}
          rows={4}
          placeholder="Comentario sobre el cliente (opcional)…"
          className="w-full resize-none rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60"
        />
      </div>
    </Modal>
  );
}

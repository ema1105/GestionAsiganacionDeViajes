import { useEffect, useRef, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Card from '../../components/ui/Card.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { IconSend, GavLogo } from '../../components/icons/Icons.jsx';
import { clienteApi } from '../../api/cliente.api.js';

const BIENVENIDA = {
  from: 'bot',
  text: 'Hola, soy el asistente GAV. Pregúntame por lugares, destinos o recomendaciones en Cartagena de Indias y te ayudo a planear tu viaje.',
};

export default function ChatbotPage() {
  const [mensajes, setMensajes] = useState([BIENVENIDA]);
  const [input, setInput] = useState('');
  const [enviando, setEnviando] = useState(false);
  const [sugerencias, setSugerencias] = useState([]);
  const finRef = useRef(null);

  useEffect(() => {
    clienteApi.lugaresMasSolicitados(6).then((d) => {
      const arr = Array.isArray(d) ? d : (d?.content ?? []);
      setSugerencias(arr.map((l) => l.nombre).filter(Boolean).slice(0, 5));
    });
  }, []);

  useEffect(() => {
    finRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [mensajes, enviando]);

  const enviar = async (texto) => {
    const msg = (texto ?? input).trim();
    if (!msg || enviando) return;
    setMensajes((m) => [...m, { from: 'user', text: msg }]);
    setInput('');
    setEnviando(true);
    try {
      const data = await clienteApi.chatbotMensaje(msg);
      const respuesta =
        data?.respuesta ?? data?.mensaje ?? 'No recibí respuesta del asistente.';
      setMensajes((m) => [...m, { from: 'bot', text: respuesta }]);
    } catch (e) {
      setMensajes((m) => [
        ...m,
        {
          from: 'bot',
          text:
            e.mensaje ||
            'El asistente no está disponible en este momento. Inténtalo más tarde.',
        },
      ]);
    } finally {
      setEnviando(false);
    }
  };

  return (
    <div>
      <PageHeader
        title="Asistente IA"
        subtitle="Recomendaciones de lugares y destinos en Cartagena"
      />

      <Card className="flex h-[68vh] flex-col p-0">
        {/* Conversación */}
        <div className="flex-1 space-y-4 overflow-y-auto p-6">
          {mensajes.map((m, i) => (
            <div
              key={i}
              className={`flex items-start gap-3 ${
                m.from === 'user' ? 'flex-row-reverse' : ''
              }`}
            >
              {m.from === 'bot' && (
                <div className="mt-0.5 shrink-0">
                  <GavLogo size={28} />
                </div>
              )}
              <div
                className={`max-w-[75%] rounded-2xl px-4 py-3 text-sm leading-relaxed ${
                  m.from === 'user'
                    ? 'rounded-tr-sm bg-gold/15 text-ink'
                    : 'rounded-tl-sm border border-line bg-surface text-subtle'
                }`}
              >
                {m.text}
              </div>
            </div>
          ))}

          {enviando && (
            <div className="flex items-center gap-3">
              <GavLogo size={28} />
              <div className="rounded-2xl rounded-tl-sm border border-line bg-surface px-4 py-3">
                <Spinner size="h-4 w-4" />
              </div>
            </div>
          )}
          <div ref={finRef} />
        </div>

        {/* Sugerencias */}
        {sugerencias.length > 0 && (
          <div className="flex flex-wrap gap-2 border-t border-line px-6 py-3">
            {sugerencias.map((s) => (
              <button
                key={s}
                onClick={() => enviar(`Cuéntame sobre ${s}`)}
                className="rounded-full border border-line px-3 py-1 text-xs text-muted transition-colors hover:border-gold/40 hover:text-gold"
              >
                {s}
              </button>
            ))}
          </div>
        )}

        {/* Input */}
        <form
          onSubmit={(e) => {
            e.preventDefault();
            enviar();
          }}
          className="flex items-center gap-3 border-t border-line p-4"
        >
          <input
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Escribe tu pregunta…"
            className="flex-1 rounded-lg border border-line bg-surface px-4 py-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60"
          />
          <button
            type="submit"
            disabled={enviando || !input.trim()}
            className="lift flex h-11 w-11 items-center justify-center rounded-lg bg-gold text-base transition disabled:opacity-50"
            aria-label="Enviar"
          >
            <IconSend width={18} height={18} />
          </button>
        </form>
      </Card>
    </div>
  );
}

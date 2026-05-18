import {
  createContext,
  useContext,
  useState,
  useCallback,
  useMemo,
} from 'react';

const ToastContext = createContext(null);

let idSeq = 0;

// Provee toasts flotantes globales. Se monta una sola vez en main.jsx.
export function ToastProvider({ children }) {
  const [toasts, setToasts] = useState([]);

  const dismiss = useCallback((id) => {
    setToasts((t) => t.filter((x) => x.id !== id));
  }, []);

  const push = useCallback(
    (mensaje, tipo = 'success') => {
      const id = ++idSeq;
      setToasts((t) => [...t, { id, mensaje, tipo }]);
      setTimeout(() => dismiss(id), 3500);
    },
    [dismiss]
  );

  // Referencia ESTABLE: si se recreara en cada render, cambiaría el `value`
  // del Context y todo consumidor con `useEffect(..., [toast])` entraría en
  // bucle de re-fetch. `push` ya es estable (useCallback), así que el objeto
  // solo se crea una vez.
  const toast = useMemo(
    () => ({
      success: (m) => push(m, 'success'),
      error: (m) => push(m, 'error'),
      info: (m) => push(m, 'info'),
    }),
    [push]
  );

  return (
    <ToastContext.Provider value={toast}>
      {children}
      <div className="fixed bottom-6 right-6 z-[100] flex flex-col gap-2.5">
        {toasts.map((t) => (
          <div
            key={t.id}
            className={`animate-toast-in flex min-w-[260px] items-start gap-3 rounded-lg
              border bg-surface px-4 py-3 text-sm shadow-premium
              ${
                t.tipo === 'success'
                  ? 'border-gold/30'
                  : t.tipo === 'error'
                    ? 'border-red-500/30'
                    : 'border-line'
              }`}
          >
            <span
              className={`mt-1.5 h-2 w-2 shrink-0 rounded-full ${
                t.tipo === 'success'
                  ? 'bg-gold'
                  : t.tipo === 'error'
                    ? 'bg-red-400'
                    : 'bg-subtle'
              }`}
            />
            <p className="flex-1 text-subtle">{t.mensaje}</p>
            <button
              onClick={() => dismiss(t.id)}
              className="text-muted transition-colors hover:text-ink"
              aria-label="Cerrar"
            >
              ×
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  );
}

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) throw new Error('useToast debe usarse dentro de <ToastProvider>');
  return ctx;
}

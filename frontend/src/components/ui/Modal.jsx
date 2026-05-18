import { useEffect } from 'react';
import { IconClose } from '../icons/Icons.jsx';

// Modal reutilizable con overlay oscuro translúcido + animación.
// Cierra con ESC o click en el overlay.
export default function Modal({ open, onClose, title, children, footer }) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e) => e.key === 'Escape' && onClose?.();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-4 backdrop-blur-sm animate-fade-in"
      onClick={onClose}
    >
      <div
        className="w-full max-w-lg animate-slide-up rounded-2xl border border-line bg-surface shadow-premium"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between border-b border-line px-6 py-4">
          <h3 className="font-serif text-xl text-ink">{title}</h3>
          <button
            onClick={onClose}
            className="text-muted transition-colors hover:text-ink"
            aria-label="Cerrar"
          >
            <IconClose />
          </button>
        </div>
        <div className="px-6 py-5">{children}</div>
        {footer && (
          <div className="flex justify-end gap-3 border-t border-line px-6 py-4">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

import { useState } from 'react';
import { IconEye, IconEyeOff } from '../icons/Icons.jsx';

// Input premium con label uppercase, error inline y toggle de visibilidad
// automático cuando type="password".
export default function Input({
  label,
  error,
  id,
  type = 'text',
  className = '',
  ...props
}) {
  const [show, setShow] = useState(false);
  const isPassword = type === 'password';
  const realType = isPassword ? (show ? 'text' : 'password') : type;

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={id} className="label-premium">
          {label}
        </label>
      )}
      <div className="relative">
        <input
          id={id}
          type={realType}
          className={`w-full rounded-lg border bg-surface px-3.5 py-3 text-sm text-ink
            placeholder:text-muted outline-none transition-all duration-200
            focus:border-gold/60 focus:ring-1 focus:ring-gold/30
            ${error ? 'border-red-500/60' : 'border-line'}
            ${isPassword ? 'pr-11' : ''} ${className}`}
          {...props}
        />
        {isPassword && (
          <button
            type="button"
            onClick={() => setShow((s) => !s)}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-muted transition-colors hover:text-gold"
            tabIndex={-1}
            aria-label={show ? 'Ocultar contraseña' : 'Mostrar contraseña'}
          >
            {show ? <IconEyeOff /> : <IconEye />}
          </button>
        )}
      </div>
      {error && <span className="text-xs text-red-400">{error}</span>}
    </div>
  );
}

import Spinner from './Spinner.jsx';

// Botón premium. Variantes:
//  - primary  : beige claro sobre oscuro, elevación en hover
//  - outline  : borde dorado sutil, transparente
//  - ghost    : sin fondo, para acciones secundarias
//  - danger   : hover rojizo suave
export default function Button({
  children,
  loading = false,
  disabled = false,
  variant = 'primary',
  type = 'button',
  className = '',
  ...props
}) {
  const base =
    'inline-flex items-center justify-center gap-2 rounded-lg px-4 py-2.5 text-sm ' +
    'font-medium lift disabled:cursor-not-allowed disabled:opacity-50';

  const variants = {
    primary:
      'bg-cream text-base hover:bg-white shadow-premium',
    outline:
      'border border-line text-subtle hover:border-gold hover:text-gold bg-transparent',
    ghost: 'text-subtle hover:bg-surface hover:text-ink',
    danger:
      'border border-line text-subtle hover:border-red-500/40 hover:text-red-400 hover:bg-red-500/5',
    gold: 'bg-gold text-base hover:bg-gold-soft shadow-glow',
  };

  return (
    <button
      type={type}
      disabled={disabled || loading}
      className={`${base} ${variants[variant]} ${className}`}
      {...props}
    >
      {loading && <Spinner size="h-4 w-4" />}
      {children}
    </button>
  );
}

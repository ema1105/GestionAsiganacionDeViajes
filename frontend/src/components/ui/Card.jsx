// Contenedor premium estándar: superficie oscura, borde sutil, sombra.
export default function Card({ children, className = '', ...props }) {
  return (
    <div
      className={`rounded-xl border border-line bg-surface shadow-premium ${className}`}
      {...props}
    >
      {children}
    </div>
  );
}

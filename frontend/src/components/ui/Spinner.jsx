export default function Spinner({ size = 'h-6 w-6' }) {
  return (
    <div
      className={`${size} animate-spin rounded-full border-2 border-line border-t-gold`}
      role="status"
      aria-label="Cargando"
    />
  );
}

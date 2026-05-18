// Encabezado de página premium: título serif, subtítulo y slot de acciones.
export default function PageHeader({ title, subtitle, actions }) {
  return (
    <div className="mb-8 flex flex-wrap items-end justify-between gap-4">
      <div>
        <h1 className="font-serif text-3xl text-ink lg:text-4xl">{title}</h1>
        {subtitle && (
          <p className="mt-1.5 text-sm text-muted">{subtitle}</p>
        )}
      </div>
      {actions && <div className="flex gap-3">{actions}</div>}
    </div>
  );
}

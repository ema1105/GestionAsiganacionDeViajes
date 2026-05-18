// Encabezado de página premium: título serif, subtítulo y slot de acciones.
export default function PageHeader({ title, subtitle, actions }) {
  return (
    <div className="mb-6 flex flex-col gap-4 sm:mb-8 sm:flex-row sm:flex-wrap sm:items-end sm:justify-between">
      <div>
        <h1 className="font-serif text-2xl text-ink sm:text-3xl lg:text-4xl">
          {title}
        </h1>
        {subtitle && (
          <p className="mt-1.5 text-sm text-muted">{subtitle}</p>
        )}
      </div>
      {actions && (
        <div className="flex flex-wrap gap-3">{actions}</div>
      )}
    </div>
  );
}

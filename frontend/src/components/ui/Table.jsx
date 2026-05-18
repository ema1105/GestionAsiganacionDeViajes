// Tabla premium: header tenue, filas con hover suave y separadores sutiles.
// Uso: <Table head={['A','B']}><tr>...</tr></Table>
export default function Table({ head = [], children, empty = 'Sin registros' }) {
  return (
    <div className="-mx-4 overflow-x-auto rounded-xl border-y border-line sm:mx-0 sm:border sm:border-line">
      <table className="w-full min-w-[640px] border-collapse text-sm">
        <thead>
          <tr className="border-b border-line bg-panel/60">
            {head.map((h) => (
              <th
                key={h}
                className="px-5 py-3.5 text-left text-[11px] font-medium uppercase tracking-wider text-muted"
              >
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {children ?? (
            <tr>
              <td
                colSpan={head.length}
                className="px-5 py-10 text-center text-muted"
              >
                {empty}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

// Fila estándar con hover dorado tenue.
export function Row({ children }) {
  return (
    <tr className="border-b border-line/60 transition-colors duration-200 last:border-0 hover:bg-active/40">
      {children}
    </tr>
  );
}

export function Cell({ children, className = '' }) {
  return <td className={`px-5 py-4 text-subtle ${className}`}>{children}</td>;
}

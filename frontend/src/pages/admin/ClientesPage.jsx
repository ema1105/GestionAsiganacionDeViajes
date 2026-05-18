import { useEffect, useMemo, useState } from 'react';
import PageHeader from '../../components/ui/PageHeader.jsx';
import Table, { Row, Cell } from '../../components/ui/Table.jsx';
import Spinner from '../../components/ui/Spinner.jsx';
import { IconSearch } from '../../components/icons/Icons.jsx';
import { adminApi } from '../../api/admin.api.js';
import { useToast } from '../../context/ToastContext.jsx';

const fmtFecha = (f) => {
  if (!f) return '—';
  try {
    return new Date(f).toLocaleDateString('es-CO', {
      year: 'numeric',
      month: 'short',
      day: '2-digit',
    });
  } catch {
    return f;
  }
};

export default function ClientesPage() {
  const toast = useToast();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState([]);
  const [q, setQ] = useState('');

  useEffect(() => {
    adminApi
      .listarClientes()
      .then((d) => setData(Array.isArray(d) ? d : d?.content ?? []))
      .catch(() => toast.error('Error al cargar clientes'))
      .finally(() => setLoading(false));
  }, [toast]);

  const filtrados = useMemo(
    () =>
      data.filter((c) => {
        if (!q) return true;
        const txt = `${c.nombreCompleto ?? ''} ${c.email ?? ''}`.toLowerCase();
        return txt.includes(q.toLowerCase());
      }),
    [data, q]
  );

  return (
    <div>
      <PageHeader
        title="Gestión de Clientes"
        subtitle="Usuarios registrados en la plataforma GAV"
      />

      <div className="relative mb-5 max-w-md">
        <IconSearch
          width={16}
          height={16}
          className="absolute left-3.5 top-1/2 -translate-y-1/2 text-muted"
        />
        <input
          value={q}
          onChange={(e) => setQ(e.target.value)}
          placeholder="Buscar por nombre o correo..."
          className="w-full rounded-lg border border-line bg-surface py-2.5 pl-10 pr-3 text-sm text-ink placeholder:text-muted outline-none focus:border-gold/60"
        />
      </div>

      {loading ? (
        <div className="flex h-64 items-center justify-center">
          <Spinner size="h-8 w-8" />
        </div>
      ) : (
        <Table
          head={[
            'ID',
            'Nombre completo',
            'Correo',
            'Teléfono',
            'Viajes',
            'Registro',
          ]}
          empty="No hay clientes para mostrar"
        >
          {filtrados.length > 0 &&
            filtrados.map((c) => (
              <Row key={c.id}>
                <Cell className="text-muted">#{c.id}</Cell>
                <Cell className="text-ink">
                  {c.nombreCompleto} {c.apellidosCompletos ?? ''}
                </Cell>
                <Cell>{c.email ?? '—'}</Cell>
                <Cell>{c.telefono ?? '—'}</Cell>
                <Cell className="text-ink">{c.totalViajes ?? 0}</Cell>
                <Cell className="text-muted">
                  {fmtFecha(c.fechaRegistro ?? c.fechaCreacion)}
                </Cell>
              </Row>
            ))}
        </Table>
      )}
    </div>
  );
}

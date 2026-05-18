import { Link } from 'react-router-dom';

export default function NotFoundPage() {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center gap-3 bg-base text-center">
      <h1 className="font-serif text-7xl text-gold">404</h1>
      <p className="text-subtle">La página que buscas no existe.</p>
      <Link
        to="/"
        className="mt-2 text-sm text-gold underline-offset-4 hover:underline"
      >
        Volver al inicio
      </Link>
    </div>
  );
}

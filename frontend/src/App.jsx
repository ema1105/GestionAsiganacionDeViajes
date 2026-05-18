import AppRouter from './routes/AppRouter.jsx';

// Punto de entrada de la UI. El estado de autenticación lo provee
// AuthProvider (ver main.jsx); aquí solo montamos el router.
export default function App() {
  return <AppRouter />;
}

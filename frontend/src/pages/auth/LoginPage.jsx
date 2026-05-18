import { useState } from 'react';
import { useNavigate, useLocation, Navigate } from 'react-router-dom';
import { useAuth } from '../../hooks/useAuth.js';
import { authApi } from '../../api/auth.api.js';
import { HOME_BY_ROLE } from '../../constants/roles.js';
import { useToast } from '../../context/ToastContext.jsx';
import Input from '../../components/ui/Input.jsx';
import Button from '../../components/ui/Button.jsx';
import { GavLogo } from '../../components/icons/Icons.jsx';
import AbstractComposition from '../../components/auth/AbstractComposition.jsx';

const TIPOS_DOC = ['CC', 'TI', 'PASAPORTE', 'CE', 'PERMISO_PERMANECIA'];

export default function LoginPage() {
  const { login, isAuthenticated, user } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const toast = useToast();

  const [tab, setTab] = useState('login'); // 'login' | 'register'
  const [loading, setLoading] = useState(false);
  const [serverError, setServerError] = useState('');

  const [loginForm, setLoginForm] = useState({
    nombreUsuario: '',
    contrasena: '',
  });
  const [regForm, setRegForm] = useState({
    nombreCompleto: '',
    apellidosCompletos: '',
    fechaNacimiento: '',
    tipoDocumento: 'CC',
    numeroDocumento: '',
    email: '',
    telefono: '',
    nombreUsuario: '',
    contrasena: '',
  });
  const [errors, setErrors] = useState({});

  if (isAuthenticated) {
    return <Navigate to={HOME_BY_ROLE[user?.rol] ?? '/'} replace />;
  }

  const handleLogin = async (e) => {
    e.preventDefault();
    setServerError('');
    const errs = {};
    if (!loginForm.nombreUsuario.trim())
      errs.nombreUsuario = 'Requerido';
    if (!loginForm.contrasena) errs.contrasena = 'Requerido';
    setErrors(errs);
    if (Object.keys(errs).length) return;

    setLoading(true);
    try {
      const data = await login(
        loginForm.nombreUsuario.trim(),
        loginForm.contrasena
      );
      const from = location.state?.from?.pathname;
      navigate(from ?? HOME_BY_ROLE[data.rol] ?? '/', { replace: true });
    } catch (err) {
      setServerError(
        err.status === 401
          ? 'Usuario o contraseña incorrectos'
          : err.mensaje || 'Error al iniciar sesión'
      );
    } finally {
      setLoading(false);
    }
  };

  const handleRegister = async (e) => {
    e.preventDefault();
    setServerError('');
    const errs = {};
    [
      'nombreCompleto',
      'apellidosCompletos',
      'fechaNacimiento',
      'numeroDocumento',
      'email',
      'telefono',
      'nombreUsuario',
      'contrasena',
    ].forEach((f) => {
      if (!String(regForm[f]).trim()) errs[f] = 'Requerido';
    });
    if (regForm.email && !/^[^@]+@[^@]+\.[^@]+$/.test(regForm.email))
      errs.email = 'Correo inválido';
    if (regForm.contrasena && regForm.contrasena.length < 4)
      errs.contrasena = 'Mínimo 4 caracteres';
    setErrors(errs);
    if (Object.keys(errs).length) return;

    setLoading(true);
    try {
      await authApi.registerCliente(regForm);
      toast.success('Cuenta creada. Ya puedes iniciar sesión.');
      setTab('login');
      setLoginForm({
        nombreUsuario: regForm.nombreUsuario,
        contrasena: '',
      });
    } catch (err) {
      setServerError(err.mensaje || 'No se pudo completar el registro');
    } finally {
      setLoading(false);
    }
  };

  const reg = (field) => ({
    value: regForm[field],
    onChange: (e) => setRegForm({ ...regForm, [field]: e.target.value }),
    error: errors[field],
  });

  return (
    <div className="flex min-h-screen">
      {/* Columna izquierda — branding premium oscuro */}
      <div className="relative hidden w-1/2 flex-col justify-between overflow-hidden bg-base p-12 lg:flex">
        <AbstractComposition className="absolute inset-0 h-full w-full" />
        <div
          className="absolute inset-0"
          style={{
            background:
              'linear-gradient(180deg, rgba(13,13,13,0.55) 0%, rgba(13,13,13,0.25) 45%, rgba(13,13,13,0.8) 100%)',
          }}
        />

        <div className="relative flex items-center gap-3">
          <GavLogo size={40} />
          <span className="font-serif text-3xl font-semibold text-ink">
            GAV
          </span>
        </div>

        <div className="relative max-w-md">
          <h1 className="font-serif text-5xl leading-tight text-ink">
            Mueve{' '}
            <span className="italic text-gold">Cartagena</span> con precisión
          </h1>
          <p className="mt-5 text-sm leading-relaxed text-subtle/70">
            Plataforma ejecutiva de asignación inteligente de viajes. Control
            total de conductores, flota y operación en tiempo real, con la
            elegancia que tu operación merece.
          </p>
        </div>

        <div className="relative flex items-center gap-3 text-[11px] uppercase tracking-[0.2em] text-muted">
          <span className="h-px w-10 bg-gold/40" />
          Tecnología corporativa de movilidad
        </div>
      </div>

      {/* Columna derecha — formulario */}
      <div className="flex w-full items-center justify-center bg-base px-6 py-12 lg:w-1/2">
        <div className="w-full max-w-[400px]">
          <p className="text-[11px] uppercase tracking-[0.2em] text-gold">
            Plataforma GAV
          </p>
          <h2 className="mt-2 font-serif text-4xl text-ink">
            {tab === 'login' ? 'Bienvenido de vuelta' : 'Crea tu cuenta'}
          </h2>

          {/* Tabs */}
          <div className="mt-8 flex gap-1 rounded-lg border border-line bg-surface p-1">
            {['login', 'register'].map((t) => (
              <button
                key={t}
                onClick={() => {
                  setTab(t);
                  setErrors({});
                  setServerError('');
                }}
                className={`flex-1 rounded-md py-2 text-sm font-medium transition-all duration-200 ${
                  tab === t
                    ? 'bg-active text-gold'
                    : 'text-muted hover:text-subtle'
                }`}
              >
                {t === 'login' ? 'Iniciar sesión' : 'Registrarse'}
              </button>
            ))}
          </div>

          {serverError && (
            <div className="mt-5 rounded-lg border border-red-500/30 bg-red-500/5 px-3.5 py-2.5 text-sm text-red-400">
              {serverError}
            </div>
          )}

          {tab === 'login' ? (
            <form onSubmit={handleLogin} className="mt-6 flex flex-col gap-4" noValidate>
              <Input
                id="nombreUsuario"
                label="Nombre de usuario"
                placeholder="admin"
                value={loginForm.nombreUsuario}
                onChange={(e) =>
                  setLoginForm({ ...loginForm, nombreUsuario: e.target.value })
                }
                error={errors.nombreUsuario}
                autoComplete="username"
              />
              <Input
                id="contrasena"
                type="password"
                label="Contraseña"
                placeholder="••••••••"
                value={loginForm.contrasena}
                onChange={(e) =>
                  setLoginForm({ ...loginForm, contrasena: e.target.value })
                }
                error={errors.contrasena}
                autoComplete="current-password"
              />
              <Button
                type="submit"
                loading={loading}
                className="mt-2 w-full"
              >
                {loading ? 'Ingresando...' : 'Iniciar sesión'}
              </Button>
            </form>
          ) : (
            <form
              onSubmit={handleRegister}
              className="mt-6 grid grid-cols-2 gap-4"
              noValidate
            >
              <Input id="nombreCompleto" label="Nombres" {...reg('nombreCompleto')} />
              <Input
                id="apellidosCompletos"
                label="Apellidos"
                {...reg('apellidosCompletos')}
              />
              <Input
                id="fechaNacimiento"
                type="date"
                label="Nacimiento"
                {...reg('fechaNacimiento')}
              />
              <div className="flex flex-col gap-1.5">
                <label htmlFor="tipoDocumento" className="label-premium">
                  Tipo doc.
                </label>
                <select
                  id="tipoDocumento"
                  value={regForm.tipoDocumento}
                  onChange={(e) =>
                    setRegForm({ ...regForm, tipoDocumento: e.target.value })
                  }
                  className="rounded-lg border border-line bg-surface px-3.5 py-3 text-sm text-ink outline-none focus:border-gold/60"
                >
                  {TIPOS_DOC.map((t) => (
                    <option key={t} value={t} className="bg-surface">
                      {t}
                    </option>
                  ))}
                </select>
              </div>
              <Input
                id="numeroDocumento"
                label="N° Documento"
                {...reg('numeroDocumento')}
              />
              <Input id="telefono" label="Teléfono" {...reg('telefono')} />
              <div className="col-span-2">
                <Input
                  id="email"
                  type="email"
                  label="Correo electrónico"
                  {...reg('email')}
                />
              </div>
              <Input
                id="reg-usuario"
                label="Usuario"
                {...reg('nombreUsuario')}
              />
              <Input
                id="reg-pass"
                type="password"
                label="Contraseña"
                {...reg('contrasena')}
              />
              <div className="col-span-2">
                <Button type="submit" loading={loading} className="w-full">
                  {loading ? 'Creando cuenta...' : 'Crear cuenta'}
                </Button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
}

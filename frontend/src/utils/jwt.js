// Decodifica el payload de un JWT (parte central, Base64Url) sin verificar
// la firma. La verificación real la hace el backend; en el cliente solo
// leemos claims (rol, exp, sub) para decisiones de UI.
export function decodeToken(token) {
  try {
    const payload = token.split('.')[1];
    const base64 = payload.replace(/-/g, '+').replace(/_/g, '/');
    const json = decodeURIComponent(
      atob(base64)
        .split('')
        .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
        .join('')
    );
    return JSON.parse(json);
  } catch {
    return null;
  }
}

// true si el token no existe, es ilegible o su 'exp' ya pasó.
export function isTokenExpired(token) {
  const claims = decodeToken(token);
  if (!claims || !claims.exp) return true;
  // exp viene en segundos (estándar JWT); Date.now() en ms.
  return claims.exp * 1000 <= Date.now();
}

/// Roles tal como los emite el backend en el claim `rol` del JWT (con prefijo ROLE_).
enum Rol {
  cliente('ROLE_CLIENTE', 'Cliente', '/cliente'),
  conductor('ROLE_CONDUCTOR', 'Conductor', '/conductor'),
  admin('ROLE_ADMIN', 'Administrador', '/admin'),
  recepcionista('ROLE_RECEPCIONISTA', 'Recepcionista', '/no-soportado'),
  desconocido('', 'Desconocido', '/no-soportado');

  const Rol(this.api, this.etiqueta, this.homePath);

  final String api;
  final String etiqueta;

  /// Ruta inicial del rol. La recepcionista sigue en el panel web (React).
  final String homePath;

  bool get soportadoEnMovil => this == cliente || this == conductor || this == admin;

  static Rol fromApi(String? valor) {
    if (valor == null) return desconocido;
    final normalizado = valor.startsWith('ROLE_') ? valor : 'ROLE_$valor';
    return values.firstWhere((r) => r.api == normalizado, orElse: () => desconocido);
  }
}

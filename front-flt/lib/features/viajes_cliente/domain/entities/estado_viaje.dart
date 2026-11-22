/// Espejo de `Viaje.EstadoViaje` del backend.
/// [desconocido] evita que la app se rompa si el backend agrega un estado nuevo.
enum EstadoViaje {
  solicitado('SOLICITADO', 'Solicitado'),
  buscandoConductor('BUSCANDO_CONDUCTOR', 'Buscando conductor'),
  aceptado('ACEPTADO', 'Aceptado'),
  enCamino('EN_CAMINO', 'Conductor en camino'),
  enCurso('EN_CURSO', 'En curso'),
  finalizado('FINALIZADO', 'Finalizado'),
  cancelado('CANCELADO', 'Cancelado'),
  desconocido('DESCONOCIDO', 'Desconocido');

  const EstadoViaje(this.api, this.etiqueta);

  final String api;
  final String etiqueta;

  static EstadoViaje fromApi(String? v) =>
      values.firstWhere((e) => e.api == v, orElse: () => desconocido);

  bool get esperandoConductor => this == solicitado || this == buscandoConductor;
  bool get enProceso => this == aceptado || this == enCamino || this == enCurso;
  bool get terminado => this == finalizado || this == cancelado;

  /// El cliente puede cancelar mientras el viaje no haya iniciado.
  bool get clientePuedeCancelar => esperandoConductor || this == aceptado || this == enCamino;
}

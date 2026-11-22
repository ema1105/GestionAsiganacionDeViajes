/// Un mes calendario (`2027-10`). Es la clave de las consultas de predicción.
class Periodo implements Comparable<Periodo> {
  const Periodo(this.anio, this.mes) : assert(mes >= 1 && mes <= 12);

  /// Lee `YYYY-MM` (formato de pandas `Period` que usa el servicio).
  static Periodo? tryParse(String? s) {
    final m = RegExp(r'^(\d{4})-(\d{1,2})$').firstMatch(s?.trim() ?? '');
    if (m == null) return null;
    final mes = int.parse(m.group(2)!);
    if (mes < 1 || mes > 12) return null;
    return Periodo(int.parse(m.group(1)!), mes);
  }

  final int anio;
  final int mes;

  int get _indice => anio * 12 + (mes - 1);

  static Periodo _desdeIndice(int i) => Periodo(i ~/ 12, i % 12 + 1);

  Periodo sumarMeses(int n) => _desdeIndice(_indice + n);
  Periodo get siguiente => sumarMeses(1);
  Periodo get anterior => sumarMeses(-1);

  /// Días del mes (para el promedio diario).
  int get dias => DateTime(anio, mes + 1, 0).day;

  /// `2027-10`
  String get api => '$anio-${mes.toString().padLeft(2, '0')}';

  bool operator <(Periodo o) => compareTo(o) < 0;
  bool operator >(Periodo o) => compareTo(o) > 0;

  @override
  int compareTo(Periodo other) => _indice.compareTo(other._indice);

  @override
  bool operator ==(Object other) => other is Periodo && other._indice == _indice;

  @override
  int get hashCode => _indice.hashCode;

  @override
  String toString() => api;
}

/// Meses de [desde] a [hasta], ambos incluidos.
List<Periodo> rangoPeriodos(Periodo desde, Periodo hasta) => [
      for (var p = desde; !(p > hasta); p = p.siguiente) p,
    ];

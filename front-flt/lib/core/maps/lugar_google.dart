/// Sugerencia del autocompletado de Google (Places API New).
class SugerenciaLugar {
  const SugerenciaLugar({required this.placeId, required this.principal, this.secundario});

  final String placeId;

  /// Nombre principal ("Hospital Bocagrande").
  final String principal;

  /// Complemento ("Cra. 6, Cartagena, Bolívar").
  final String? secundario;
}

/// Lugar elegido con sus coordenadas, ya resuelto con Place Details.
class LugarGoogle {
  const LugarGoogle({required this.nombre, required this.lat, required this.lng, this.direccion});

  final String nombre;
  final String? direccion;
  final double lat;
  final double lng;
}

/// "Cra. 2 #5-10, Bocagrande, Cartagena de Indias, Bolívar, Colombia"
///   → "Cra. 2 #5-10, Bocagrande".
/// Quita ciudad, departamento, país y códigos postales para que el nombre quepa en las tarjetas.
String acortarDireccion(String direccion) {
  const omitir = ['colombia', 'bolívar', 'bolivar', 'cartagena'];
  final partes = direccion
      .split(',')
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .where((p) => !omitir.any((o) => p.toLowerCase().contains(o)))
      .where((p) => !RegExp(r'^\d{5,6}$').hasMatch(p))
      .take(2)
      .toList();
  return partes.isEmpty ? 'Punto en el mapa' : partes.join(', ');
}
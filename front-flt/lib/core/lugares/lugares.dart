import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// Catálogo de lugares de Cartagena (mismo contenido que `LugarSeeder` del backend).
/// Se usa para elegir origen/destino y para mostrar rutas legibles
/// ("Hotel Las Américas → Aeropuerto") a partir de las coordenadas del viaje.
class Lugar {
  const Lugar(this.nombre, this.corto, this.categoria, this.lat, this.lng, {this.radioMetros = 250});
  final String nombre;

  /// Nombre corto para las tarjetas ("Aeropuerto", "Bocagrande").
  final String corto;
  final String categoria;
  final double lat;
  final double lng;
  final int radioMetros;

  IconData get icono => switch (categoria) {
        'AEROPUERTO' => Icons.flight_takeoff,
        'HOTEL' => Icons.hotel_outlined,
        'PLAYA' => Icons.beach_access_outlined,
        'MALL' => Icons.shopping_bag_outlined,
        'MUSEO' => Icons.museum_outlined,
        'RESTAURANTE' => Icons.restaurant_outlined,
        'BAR' => Icons.local_bar_outlined,
        'PARQUE' => Icons.park_outlined,
        'ZONA_HISTORICA' => Icons.account_balance_outlined,
        _ => Icons.place_outlined,
      };
}

abstract final class Lugares {
  static const todos = <Lugar>[
    Lugar('Hotel Las Américas', 'Hotel Las Américas', 'HOTEL', 10.4540, -75.5050, radioMetros: 300),
    Lugar('Aeropuerto Internacional Rafael Núñez', 'Aeropuerto', 'AEROPUERTO', 10.4424, -75.5130, radioMetros: 300),
    Lugar('Ciudad Amurallada (Centro Histórico)', 'Centro Histórico', 'ZONA_HISTORICA', 10.4236, -75.5510),
    Lugar('Torre del Reloj', 'Torre del Reloj', 'ZONA_HISTORICA', 10.4225, -75.5510, radioMetros: 120),
    Lugar('Castillo San Felipe de Barajas', 'Castillo San Felipe', 'ZONA_HISTORICA', 10.4226, -75.5390),
    Lugar('Getsemaní', 'Getsemaní', 'ZONA_HISTORICA', 10.4200, -75.5450),
    Lugar('Las Bóvedas', 'Las Bóvedas', 'ZONA_HISTORICA', 10.4280, -75.5500),
    Lugar('Plaza Santo Domingo', 'Plaza Santo Domingo', 'ZONA_HISTORICA', 10.4244, -75.5515, radioMetros: 100),
    Lugar('Playa de Bocagrande', 'Bocagrande', 'PLAYA', 10.4000, -75.5550, radioMetros: 400),
    Lugar('Playa de Castillogrande', 'Castillogrande', 'PLAYA', 10.3950, -75.5600, radioMetros: 400),
    Lugar('Playa Blanca (Barú)', 'Playa Blanca', 'PLAYA', 10.1700, -75.6500, radioMetros: 800),
    Lugar('Mall Plaza El Castillo', 'Mall Plaza', 'MALL', 10.4218, -75.5403),
    Lugar('Centro Comercial Caribe Plaza', 'Caribe Plaza', 'MALL', 10.4090, -75.5360),
    Lugar('Centro Comercial La Serrezuela', 'La Serrezuela', 'MALL', 10.4257, -75.5494, radioMetros: 120),
    Lugar('Convento de la Popa', 'La Popa', 'MUSEO', 10.4180, -75.5290),
    Lugar('Museo del Oro Zenú', 'Museo del Oro', 'MUSEO', 10.4237, -75.5512, radioMetros: 80),
    Lugar('Restaurante La Cevichería', 'La Cevichería', 'RESTAURANTE', 10.4270, -75.5490, radioMetros: 100),
    Lugar('Restaurante Carmen', 'Restaurante Carmen', 'RESTAURANTE', 10.4255, -75.5495, radioMetros: 80),
    Lugar('Café del Mar', 'Café del Mar', 'BAR', 10.4248, -75.5530, radioMetros: 100),
    Lugar('Parque Centenario', 'Parque Centenario', 'PARQUE', 10.4210, -75.5460, radioMetros: 150),
    Lugar('Muelle de la Bodeguita (Islas del Rosario)', 'Muelle La Bodeguita', 'PARQUE', 10.4215, -75.5505, radioMetros: 120),
    Lugar('Barrio Crespo', 'Crespo', 'OTRO', 10.4400, -75.5160, radioMetros: 500),
  ];

  /// Distancia en línea recta (km) — fórmula de Haversine.
  static double distanciaKm(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0;
    double rad(double g) => g * math.pi / 180;
    final dLat = rad(lat2 - lat1);
    final dLng = rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.sqrt(a));
  }

  /// Lugar del catálogo más cercano a la coordenada, si está dentro de su radio
  /// (con tolerancia). null si la coordenada no corresponde a ningún lugar conocido.
  static Lugar? cercano(double lat, double lng) {
    Lugar? mejor;
    var mejorKm = double.infinity;
    for (final l in todos) {
      final km = distanciaKm(lat, lng, l.lat, l.lng);
      if (km < mejorKm) {
        mejorKm = km;
        mejor = l;
      }
    }
    if (mejor == null) return null;
    return mejorKm * 1000 <= mejor.radioMetros * 2 ? mejor : null;
  }

  /// Estimación de ruta sin Google Directions:
  /// distancia en carretera ≈ 1,35 × línea recta; velocidad urbana ≈ 24 km/h.
  /// TODO(fase mapa): reemplazar por Directions/Routes API.
  static ({double km, int minutos}) estimarRuta(Lugar a, Lugar b) {
    final km = math.max(0.5, distanciaKm(a.lat, a.lng, b.lat, b.lng) * 1.35);
    final minutos = math.max(3, (km / 24 * 60).round() + 2);
    return (km: double.parse(km.toStringAsFixed(2)), minutos: minutos);
  }
}

// Implementación por plataforma de Google Maps.
// - Web: Maps JavaScript API (script, rutas, Places y Geocoder), como el frontend React.
// - Android/iOS: SDK nativo; rutas por calles con las APIs REST de Google (Routes/Directions)
//   y, si fallan, estimación por Haversine. Sin búsqueda de Google.
export 'lugar_google.dart';
export 'maps_plataforma_stub.dart' if (dart.library.js_interop) 'maps_plataforma_web.dart';
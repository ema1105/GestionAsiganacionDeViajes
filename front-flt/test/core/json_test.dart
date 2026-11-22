import 'package:flutter_test/flutter_test.dart';
import 'package:gav_app/core/json/json_read.dart';
import 'package:gav_app/core/pagination/pagina.dart';
import 'package:gav_app/features/viajes_cliente/data/dtos/viaje_dto.dart';
import 'package:gav_app/features/viajes_cliente/domain/entities/estado_viaje.dart';

void main() {
  test('PageDto acepta "last" o "isLast" (Lombok/Jackson)', () {
    final conLast = PageDto.fromJson(
      {'content': [], 'page': 0, 'size': 20, 'totalElements': 0, 'totalPages': 0, 'last': true},
      (j) => j,
    );
    final conIsLast = PageDto.fromJson(
      {'content': [], 'page': 0, 'size': 20, 'totalElements': 30, 'totalPages': 2, 'isLast': false},
      (j) => j,
    );
    expect(conLast.last, isTrue);
    expect(conIsLast.last, isFalse);
  });

  test('ViajeDto: BigDecimal entero, nulos y estado desconocido', () {
    final v = ViajeDto.fromJson({
      'id': 7,
      'cantidadPasajeros': 2,
      'origenLat': 10, // BigDecimal sin decimales llega como int
      'origenLng': -75.5,
      'destinoLat': 10.42,
      'destinoLng': -75.53,
      'estadoViaje': 'ESTADO_NUEVO_DEL_BACKEND',
      'conductorId': null,
      'precioCalculado': 15000,
      'fechaSolicitud': '2026-11-18T22:14:05.123456',
    });
    expect(v.origenLat, 10.0);
    expect(v.conductorId, isNull);
    expect(v.estadoViaje, EstadoViaje.desconocido);
    expect(v.precioCalculado, 15000.0);
    expect(v.fechaSolicitud, isNotNull);
  });

  test('LocalDateTime sin zona se interpreta en la zona del servidor (-05:00)', () {
    final d = asServerDateTime('2026-11-18T22:00:00')!;
    expect(d.toUtc(), DateTime.utc(2026, 11, 19, 3));
  });

  test('toServerIso formatea sin zona en hora del servidor', () {
    expect(toServerIso(DateTime.utc(2026, 11, 19, 3)), '2026-11-18T22:00:00');
  });
}

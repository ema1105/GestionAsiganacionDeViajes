import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/prediccion_dio.dart';
import '../domain/entrenamiento.dart';
import '../domain/periodo.dart';
import '../domain/prediccion.dart';
import '../domain/prediccion_repository.dart';
import 'datasources/prediccion_remote_data_source.dart';
import 'prediccion_errores.dart';

class PrediccionRepositoryImpl implements PrediccionRepository {
  PrediccionRepositoryImpl(this._remote);
  final PrediccionRemoteDataSource _remote;

  @override
  Future<Prediccion> prediccion(Periodo desde, {Periodo? hasta}) => guardPrediccion(() async {
        final dto = await _remote.mensual(anio: desde.anio, mes: desde.mes, mesFin: hasta?.mes);
        return dto.toEntity();
      });

  @override
  Future<FichaModelo> ficha() => guardPrediccion(() async => (await _remote.modelo()).toEntity());

  @override
  Future<EstadoServicio> salud() => guardPrediccion(() async {
        final estado = await _remote.salud();
        return estado == 'ok' ? EstadoServicio.ok : EstadoServicio.sinModelo;
      });

  @override
  Future<EstadoEntrenamiento> reentrenar() =>
      guardPrediccion(() async => EstadoEntrenamiento.fromJson(await _remote.reentrenar()));

  @override
  Future<EstadoEntrenamiento> estadoReentrenamiento() =>
      guardPrediccion(() async => EstadoEntrenamiento.fromJson(await _remote.estadoReentrenamiento()));

  @override
  Future<EstadoEntrenamiento> restaurarModeloAnterior() =>
      guardPrediccion(() async => EstadoEntrenamiento.fromJson(await _remote.restaurar()));
}

final prediccionRepositoryProvider = Provider<PrediccionRepository>(
  (ref) => PrediccionRepositoryImpl(PrediccionRemoteDataSource(ref.watch(prediccionDioProvider))),
);

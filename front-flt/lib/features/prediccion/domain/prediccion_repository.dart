import 'entrenamiento.dart';
import 'periodo.dart';
import 'prediccion.dart';

abstract interface class PrediccionRepository {
  /// Predicción de un mes (o de [hasta] incluido, si se da) contra el año anterior.
  Future<Prediccion> prediccion(Periodo desde, {Periodo? hasta});

  Future<FichaModelo> ficha();

  /// No requiere API key: sirve para el indicador de conexión.
  Future<EstadoServicio> salud();

  /// Reentrenamiento del modelo desde la app (solo admin).
  Future<EstadoEntrenamiento> reentrenar();
  Future<EstadoEntrenamiento> estadoReentrenamiento();
  Future<EstadoEntrenamiento> restaurarModeloAnterior();
}

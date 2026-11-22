import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/error/app_failure.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Nombres de meses y días en español para DateFormat.
  await initializeDateFormatting('es');
  runApp(
    ProviderScope(
      // Riverpod 3 reintenta providers fallidos por defecto.
      // Solo reintentamos errores transitorios (red/timeout/5xx), nunca 4xx.
      retry: (intento, error) => error is AppFailure && error.isRetryable && intento < 3
          ? Duration(seconds: 1 << intento)
          : null,
      child: const GavApp(),
    ),
  );
}

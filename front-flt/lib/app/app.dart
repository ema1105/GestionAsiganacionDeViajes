import 'package:cupertino_ui/cupertino_ui.dart' show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart' show GlobalWidgetsLocalizations;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/theme/gav_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router.dart';

class GavApp extends ConsumerWidget {
  const GavApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'GAV',
        debugShowCheckedModeBanner: false,
        routerConfig: ref.watch(routerProvider),
        theme: buildGavTheme(Brightness.light),
        darkTheme: buildGavTheme(Brightness.dark),
        themeMode: ref.watch(themeControllerProvider),
        locale: const Locale('es', 'CO'),
        supportedLocales: const [Locale('es', 'CO'), Locale('es'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      );
}

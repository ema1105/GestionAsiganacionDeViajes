import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

final _registrados = <String>{};

/// Web: el reporte de Power BI en un <iframe>.
Widget buildDashboardEmbed(String url) {
  final viewType = 'gav-powerbi-${url.hashCode}';
  if (_registrados.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int _) {
      final iframe = web.HTMLIFrameElement()
        ..src = url
        ..allowFullscreen = true;
      iframe.style
        ..border = 'none'
        ..width = '100%'
        ..height = '100%';
      return iframe;
    });
  }
  return HtmlElementView(viewType: viewType);
}

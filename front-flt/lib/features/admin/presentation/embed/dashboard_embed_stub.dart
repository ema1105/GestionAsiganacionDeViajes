import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Android/iOS: el reporte de Power BI dentro de un WebView.
/// En escritorio (Windows/macOS) no hay WebView: se usa el botón "Abrir en Power BI".
Widget buildDashboardEmbed(String url) {
  final soportado = defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  if (!soportado) {
    return const Center(
      child: Text(
        'Vista embebida disponible en Android, iOS y web.\nUsa "Abrir en Power BI".',
        textAlign: TextAlign.center,
        style: TextStyle(color: Color(0xFF6B6760), fontSize: 12),
      ),
    );
  }
  return _PowerBiWebView(url: url);
}

class _PowerBiWebView extends StatefulWidget {
  const _PowerBiWebView({required this.url});
  final String url;

  @override
  State<_PowerBiWebView> createState() => _PowerBiWebViewState();
}

class _PowerBiWebViewState extends State<_PowerBiWebView> {
  late final WebViewController _controller = WebViewController()
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadRequest(Uri.parse(widget.url));

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _controller);
}

// Selecciona la implementación según la plataforma:
// - Web: <iframe> nativo (HtmlElementView).
// - Android/iOS: WebView.
export 'dashboard_embed_stub.dart' if (dart.library.js_interop) 'dashboard_embed_web.dart';

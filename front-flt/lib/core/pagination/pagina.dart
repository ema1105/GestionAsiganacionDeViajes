import '../json/json_read.dart';

/// Página de resultados ya mapeada a entidades de dominio.
class Pagina<T> {
  const Pagina({
    required this.items,
    required this.page,
    required this.totalElements,
    required this.isLast,
  });

  final List<T> items;
  final int page; // base 0, como Spring Data
  final int totalElements;
  final bool isLast;
}

/// Espejo de `PageResponse<T>` del backend.
///
/// OJO: el campo Java es `boolean isLast` con Lombok → Jackson suele publicarlo
/// como `"last"`. Aceptamos ambas claves para no depender de ese detalle.
class PageDto<T> {
  const PageDto({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PageDto.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) fromItem,
  ) {
    final raw = json['content'];
    final content = raw is List
        ? raw.map((e) => fromItem(e as Map<String, dynamic>)).toList()
        : <T>[];
    final page = asInt(json['page']) ?? 0;
    final totalPages = asInt(json['totalPages']) ?? 0;
    return PageDto(
      content: content,
      page: page,
      size: asInt(json['size']) ?? content.length,
      totalElements: asInt(json['totalElements']) ?? content.length,
      totalPages: totalPages,
      last: asBool(json['last'] ?? json['isLast'], orElse: page + 1 >= totalPages),
    );
  }

  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  Pagina<R> toPagina<R>(R Function(T) map) => Pagina(
        items: content.map(map).toList(),
        page: page,
        totalElements: totalElements,
        isLast: last,
      );
}

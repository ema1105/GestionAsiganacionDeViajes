/// Estado de una lista paginada con "cargar más" (scroll infinito).
class PaginatedState<T> {
  const PaginatedState({
    required this.items,
    required this.page,
    required this.hasMore,
    this.cargandoMas = false,
    this.errorCargaMas,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final bool cargandoMas;

  /// Error al cargar la siguiente página (la lista ya cargada se conserva).
  final Object? errorCargaMas;

  bool get isEmpty => items.isEmpty;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? cargandoMas,
    Object? errorCargaMas,
    bool limpiarError = false,
  }) =>
      PaginatedState(
        items: items ?? this.items,
        page: page ?? this.page,
        hasMore: hasMore ?? this.hasMore,
        cargandoMas: cargandoMas ?? this.cargandoMas,
        errorCargaMas: limpiarError ? null : (errorCargaMas ?? this.errorCargaMas),
      );
}

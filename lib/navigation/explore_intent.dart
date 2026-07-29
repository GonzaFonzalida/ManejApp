/// Argumentos opcionales al abrir [HomeScreen] (exploración de instructores).
class ExploreIntent {
  const ExploreIntent({
    this.preferUserAnchor = true,
    this.transmission,
    this.availableToday = false,
    this.initialInstructorNameQuery,
    this.focusZoneSearch = false,
  });

  /// Si es true, al entrar se prioriza la ubicación del usuario como centro de búsqueda.
  final bool preferUserAnchor;

  /// `AUTOMATIC` o `MANUAL`, coherente con [ApiService.getInstructors].
  final String? transmission;

  final bool availableToday;
  final String? initialInstructorNameQuery;
  final bool focusZoneSearch;

  static ExploreIntent? fromArguments(Object? raw) {
    if (raw == null) return null;
    if (raw is ExploreIntent) return raw;
    if (raw is Map) {
      return ExploreIntent(
        preferUserAnchor: raw['preferUserAnchor'] != false,
        transmission: raw['transmission'] as String?,
        availableToday: raw['availableToday'] == true,
        initialInstructorNameQuery:
            raw['initialInstructorNameQuery'] as String?,
        focusZoneSearch: raw['focusZoneSearch'] == true,
      );
    }
    return null;
  }
}

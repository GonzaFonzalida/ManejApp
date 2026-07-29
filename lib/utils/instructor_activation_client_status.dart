/// Estado de activación del instructor según el backend (`GET /instructors/me`).
///
/// Prioriza `activationClientStatus`; si la API aún no lo envía, usa el criterio
/// equivalente a `publishable && isListed` (misma regla que marca `active` en servidor).
String instructorActivationClientStatus(Map<String, dynamic>? instructor) {
  if (instructor == null) return 'blocked';
  final v = instructor['activationClientStatus']?.toString().trim();
  if (v != null && v.isNotEmpty) return v;
  final pub = instructor['publishable'];
  final listed = instructor['isListed'];
  if (pub is bool && pub && listed is bool && listed) return 'active';
  return 'blocked';
}

import 'package:url_launcher/url_launcher.dart';

/// Abre Mercado Pago en el navegador/app externa.
/// Retorna true si se pudo lanzar la URL.
Future<bool> openMercadoPagoCheckout(String initPoint) async {
  if (initPoint.isEmpty) return false;
  final uri = Uri.parse(initPoint);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

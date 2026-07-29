import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Cómo se ancla el bitmap respecto al [LatLng] en el mapa.
enum ProfileMapMarkerAnchorMode {
  /// Estilo pin: el borde inferior del círculo toca la coordenada (búsqueda, lista de instructores).
  pin,

  /// El centro del avatar coincide con la coordenada (misma que el centro del [Circle] de cobertura).
  geographicCenter,
}

/// Genera [BitmapDescriptor] circulares para markers de Google Maps (foto + borde + sombra).
/// Tamaño acorde a un pin clásico (~36px lógicos). Resultados cacheados.
class ProfileMapMarkerIconService {
  ProfileMapMarkerIconService._();
  static final ProfileMapMarkerIconService instance =
      ProfileMapMarkerIconService._();

  /// Incrementar si cambia geometría (invalida caché en disco lógica).
  static const _cacheVersion = 4;

  /// Tamaño lógico total del PNG (similar al pin por defecto de Google Maps).
  static const Size _logicalSize = Size(36, 34);

  /// ~12% más chico que la v3 para lectura premium sin perder nitidez.
  static const double _circleRadius = 8.75;
  static const Offset _circleCenter = Offset(18, 11);
  static const double _borderWidth = 1.5;
  static const double _shadowElevation = 1.15;

  final Map<String, BitmapDescriptor> _cache = {};
  final Map<String, Future<BitmapDescriptor>> _inFlight = {};
  final List<String> _cacheOrder = [];
  static const int _maxCacheEntries = 96;

  /// Anclaje recomendado según el modo (coordenadas normalizadas 0–1 del bitmap).
  static Offset anchorFor(ProfileMapMarkerAnchorMode mode) {
    switch (mode) {
      case ProfileMapMarkerAnchorMode.pin:
        final bottom = _circleCenter.dy + _circleRadius;
        return Offset(0.5, (bottom / _logicalSize.height).clamp(0.0, 1.0));
      case ProfileMapMarkerAnchorMode.geographicCenter:
        return Offset(
          (_circleCenter.dx / _logicalSize.width).clamp(0.0, 1.0),
          (_circleCenter.dy / _logicalSize.height).clamp(0.0, 1.0),
        );
    }
  }

  String _cacheKey({
    required double devicePixelRatio,
    String? imageUrl,
    required String fallbackKey,
  }) {
    final url = (imageUrl == null || imageUrl.isEmpty) ? '-' : imageUrl;
    return '${_cacheVersion}_${url}_${fallbackKey}_${devicePixelRatio.toStringAsFixed(2)}';
  }

  Future<BitmapDescriptor> descriptorForProfile({
    required double devicePixelRatio,
    String? imageUrl,
    String? fallbackLabel,
    Color fallbackColor = const Color(0xFF1565C0),
    Color borderColor = Colors.white,
  }) {
    final letter = _singleDisplayChar(fallbackLabel);
    final fk = '${Object.hash(letter, fallbackColor, borderColor)}';
    final key = _cacheKey(
      devicePixelRatio: devicePixelRatio,
      imageUrl: imageUrl,
      fallbackKey: fk,
    );

    if (_cache.containsKey(key)) {
      return Future.value(_cache[key]!);
    }
    return _inFlight.putIfAbsent(key, () async {
      try {
        final dpr = devicePixelRatio.clamp(1.0, 4.0);
        ui.Image? photo;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          photo = await _decodeNetworkImage(imageUrl);
        }
        final bytes = await _buildPngBytes(
          devicePixelRatio: dpr,
          photo: photo,
          fallbackLabel: letter,
          fallbackColor: fallbackColor,
          borderColor: borderColor,
        );
        photo?.dispose();
        final descriptor = BitmapDescriptor.bytes(bytes);
        _remember(key, descriptor);
        return descriptor;
      } finally {
        _inFlight.remove(key);
      }
    });
  }

  void _remember(String key, BitmapDescriptor descriptor) {
    if (_cache.containsKey(key)) {
      _cache[key] = descriptor;
      return;
    }
    while (_cacheOrder.length >= _maxCacheEntries) {
      final old = _cacheOrder.removeAt(0);
      _cache.remove(old);
    }
    _cacheOrder.add(key);
    _cache[key] = descriptor;
  }

  String _singleDisplayChar(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '?';
    final s = raw.trim();
    final cp = s.runes.first;
    return String.fromCharCode(cp).toUpperCase();
  }

  Future<ui.Image?> _decodeNetworkImage(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null || !uri.hasScheme) return null;
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final codec = await ui.instantiateImageCodec(res.bodyBytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List> _buildPngBytes({
    required double devicePixelRatio,
    required ui.Image? photo,
    required String fallbackLabel,
    required Color fallbackColor,
    required Color borderColor,
  }) async {
    final w = (_logicalSize.width * devicePixelRatio).round();
    final h = (_logicalSize.height * devicePixelRatio).round();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    );
    canvas.scale(devicePixelRatio);

    final shadowPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: _circleCenter.translate(0, 0.65),
          radius: _circleRadius + 0.35,
        ),
      );
    canvas.drawShadow(
      shadowPath,
      Colors.black.withValues(alpha: 0.18),
      _shadowElevation,
      false,
    );

    final fillPath = Path()
      ..addOval(Rect.fromCircle(center: _circleCenter, radius: _circleRadius));

    if (photo != null) {
      canvas.save();
      canvas.clipPath(fillPath);
      _paintImageCover(canvas, photo, _circleCenter, _circleRadius);
      canvas.restore();
    } else {
      final bgPaint = Paint()..color = fallbackColor;
      canvas.drawPath(fillPath, bgPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: fallbackLabel,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(
          _circleCenter.dx - tp.width / 2,
          _circleCenter.dy - tp.height / 2,
        ),
      );
    }

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;
    canvas.drawCircle(
        _circleCenter, _circleRadius - _borderWidth / 2, borderPaint);

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return data!.buffer.asUint8List();
  }

  void _paintImageCover(
      Canvas canvas, ui.Image image, Offset center, double radius) {
    final dst = Rect.fromCircle(center: center, radius: radius);
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();
    final dstAspect = 1.0;
    final imgAspect = iw / ih;
    late Rect src;
    if (imgAspect > dstAspect) {
      final srcW = ih.toDouble();
      final left = (iw - srcW) / 2;
      src = Rect.fromLTWH(left, 0, srcW, ih.toDouble());
    } else {
      final srcH = iw.toDouble();
      final top = (ih - srcH) / 2;
      src = Rect.fromLTWH(0, top, iw.toDouble(), srcH);
    }
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );
  }

  void clearCache() {
    _cache.clear();
    _cacheOrder.clear();
    _inFlight.clear();
  }
}

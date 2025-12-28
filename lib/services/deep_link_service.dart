import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  static StreamSubscription? _sub;
  static final _appLinks = AppLinks();

  static void init(BuildContext context) {
    _handleInitialUri(context);
    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleUri(context, uri);
    });
  }

  static void dispose() {
    _sub?.cancel();
  }

  static Future<void> _handleInitialUri(BuildContext context) async {
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) _handleUri(context, uri);
    } catch (e) {
      debugPrint('Error getting initial URI: $e');
    }
  }

  static void _handleUri(BuildContext context, Uri uri) {
    if (uri.scheme == 'manejapp' && uri.path == '/verify-email') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        Navigator.of(context).pushNamed('/verify-email', arguments: token);
      }
    }
  }
}

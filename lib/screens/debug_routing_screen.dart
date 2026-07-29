import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/secure_storage.dart';
import '../utils/role_router.dart';

/// Pantalla de observabilidad de ruteo (solo debug). Muestra token, user_id, rol desde DB, ruta resuelta y último error.
class DebugRoutingScreen extends StatefulWidget {
  static const routeName = '/debug_routing';

  const DebugRoutingScreen({super.key});

  @override
  State<DebugRoutingScreen> createState() => _DebugRoutingScreenState();
}

class _DebugRoutingScreenState extends State<DebugRoutingScreen> {
  static const _storage = appSecureStorage;

  String? _tokenStatus;
  String? _userId;
  String? _roleFromDb;
  String? _resolvedRoute;
  String? _lastError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (kReleaseMode) return;
    setState(() => _loading = true);
    try {
      final token = await _storage.read(key: 'auth_token');
      final userId = await _storage.read(key: 'user_id');
      _tokenStatus = token != null && token.isNotEmpty ? 'presente' : 'null';
      _userId = userId ?? '—';

      String? roleFromDb = '—';
      String? resolvedRoute = '—';

      if (userId != null && token != null) {
        try {
          final profile = await ApiService.getUserProfile(userId);
          roleFromDb = profile['role']?.toString() ?? '—';
        } catch (_) {
          roleFromDb = 'error al cargar';
        }
        try {
          resolvedRoute = await RoleRouter.resolveRouteForCurrentUser(
              context: 'debug_screen');
        } catch (e) {
          resolvedRoute = 'error: $e';
        }
      }

      _roleFromDb = roleFromDb;
      _resolvedRoute = resolvedRoute;
      _lastError = RoleRouter.lastRoutingError ?? '—';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('No disponible en release')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug — Ruteo'),
        backgroundColor: Colors.grey[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _row('Token', _tokenStatus ?? '—'),
                _row('user_id', _userId ?? '—'),
                _row('Rol (GET /users/:id)', _roleFromDb ?? '—'),
                _row('Ruta resuelta (RoleRouter)', _resolvedRoute ?? '—'),
                _row('Último error', _lastError ?? '—'),
              ],
            ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 4),
          SelectableText(value,
              style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}

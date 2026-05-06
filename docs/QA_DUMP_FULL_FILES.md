# QA — Dump completo de archivos modificados/creados (ruteo por rol)

Contenido completo de los archivos tocados en la implementación del plan "QA end-to-end: ruteo por rol". Referencia para revisión o restauración.

---

## Backend (repo ManejApp)

### scripts/qa-verify-endpoints.js

```javascript
/**
 * QA: Verificación de endpoints usados por RoleRouter y ApiService (Flutter).
 * Uso: QA_EMAIL=... QA_PASSWORD=... [BASE_URL=http://localhost:3000] node scripts/qa-verify-endpoints.js
 * Evidencia: imprime status + body resumido por endpoint; fallos indican fix en backend o ApiService.
 */

const BASE_URL = process.env.BASE_URL || 'http://localhost:3000';
const API = `${BASE_URL}/api/v1`;
const QA_EMAIL = process.env.QA_EMAIL || 'fig@gmail.com';
const QA_PASSWORD = process.env.QA_PASSWORD || '02320648767Si.';

const log = (label, status, bodySummary) => {
  const summary = typeof bodySummary === 'string' ? bodySummary : JSON.stringify(bodySummary ?? '').slice(0, 200);
  console.log(`[${label}] status=${status} body=${summary}`);
};

const run = async () => {
  console.log('--- QA Endpoint verification ---');
  console.log(`BASE_URL=${BASE_URL} API=${API} QA_EMAIL=${QA_EMAIL}`);
  let accessToken = null;
  let userId = null;

  // 1) POST /api/v1/auth/login
  try {
    const res = await fetch(`${API}/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: QA_EMAIL, password: QA_PASSWORD }),
    });
    const body = await res.json().catch(() => ({}));
    log('POST /auth/login', res.status, body);
    if (res.status === 200) {
      accessToken = body.accessToken ?? body.token;
      const user = body.user ?? body.data?.user;
      userId = user?.id ?? body.userId ?? body.data?.userId;
      if (!userId && accessToken && typeof accessToken === 'string' && accessToken.includes('.')) {
        try {
          const payload = JSON.parse(Buffer.from(accessToken.split('.')[1], 'base64url').toString());
          userId = payload.id ?? payload.userId ?? payload.sub;
        } catch (_) {}
      }
    }
  } catch (e) {
    log('POST /auth/login', 'ERR', e.message);
  }

  if (!accessToken || !userId) {
    console.log('--- No token/userId; skipping authenticated endpoints. ---');
    return;
  }

  const headers = { Authorization: `Bearer ${accessToken}` };

  // 2) GET /api/v1/auth/me
  try {
    const res = await fetch(`${API}/auth/me`, { headers });
    const body = await res.json().catch(() => ({}));
    log('GET /auth/me', res.status, body);
  } catch (e) {
    log('GET /auth/me', 'ERR', e.message);
  }

  // 3) GET /api/v1/users/:id (role real desde DB)
  try {
    const res = await fetch(`${API}/users/${userId}`, { headers });
    const body = await res.json().catch(() => ({}));
    log('GET /users/:id', res.status, body);
  } catch (e) {
    log('GET /users/:id', 'ERR', e.message);
  }

  // 4) GET /api/v1/instructors/me (200 ok instructor, 403 student)
  try {
    const res = await fetch(`${API}/instructors/me`, { headers });
    const body = await res.json().catch(() => ({}));
    log('GET /instructors/me', res.status, body);
  } catch (e) {
    log('GET /instructors/me', 'ERR', e.message);
  }

  // 5) PUT /api/v1/instructors/me (solo si es instructor; opcional para no modificar datos)
  try {
    const res = await fetch(`${API}/instructors/me`, {
      method: 'PUT',
      headers: { ...headers, 'Content-Type': 'application/json' },
      body: JSON.stringify({}), // empty update to only verify endpoint exists
    });
    const body = await res.json().catch(() => ({}));
    log('PUT /instructors/me', res.status, res.status === 200 ? 'OK' : body);
  } catch (e) {
    log('PUT /instructors/me', 'ERR', e.message);
  }

  console.log('--- End ---');
};

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
```

### docs/QA_ENDPOINTS_VERIFICATION.md

(Véase el archivo en el repo; contenido ya documentado en la sección "Evidencia capturada" y tabla de endpoints.)

### docs/ROUTING_QA_CHECKLIST.md

(Véase el archivo en el repo; checklist E2E, limpiar storage, flows INSTRUCTOR/STUDENT, restart, JWT stale, error handling.)

---

## Frontend (repo ManejApp-frontend)

### lib/utils/role_router.dart

```dart
import 'dart:developer' as developer;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_service.dart';
import '../screens/admin_dashboard_screen.dart';
import '../screens/complete_instructor_profile_screen.dart';
import '../screens/home_screen.dart';
import '../screens/instructor_dashboard_screen.dart';
import '../screens/login_screen.dart';

const _storage = FlutterSecureStorage();

/// Optional overrides for testing. When null, production uses [FlutterSecureStorage] and [ApiService].
class RoleRouterOverrides {
  final Future<String?> Function(String key)? storageRead;
  final Future<void> Function()? apiGetMe;
  final Future<Map<String, dynamic>> Function(String userId)? apiGetUserProfile;
  final Future<Map<String, dynamic>?> Function()? apiGetInstructorMeOrNull;

  const RoleRouterOverrides({
    this.storageRead,
    this.apiGetMe,
    this.apiGetUserProfile,
    this.apiGetInstructorMeOrNull,
  });
}

class RoleRouter {
  /// Último error capturado durante resolución de ruta (solo para debug/observabilidad).
  static String? lastRoutingError;

  static void setLastError(String? error) {
    lastRoutingError = error;
  }

  static Future<String> resolveInitialRoute({RoleRouterOverrides? overrides}) async {
    final read = overrides?.storageRead ?? ((key) => _storage.read(key: key));
    final token = await read('auth_token');
    final userId = await read('user_id');

    developer.log(
      '[RoleRouter] startup: token=${token != null ? "present" : "null"} userId=$userId',
      name: 'RoleRouter',
    );

    if (token == null || userId == null) {
      developer.log('[RoleRouter] startup: → Login', name: 'RoleRouter');
      return LoginScreen.routeName;
    }

    return resolveRouteForCurrentUser(context: 'startup', overrides: overrides);
  }

  static Future<String> resolveRouteForCurrentUser({
    required String context,
    RoleRouterOverrides? overrides,
  }) async {
    developer.log('[RoleRouter] resolveRouteForCurrentUser ctx=$context', name: 'RoleRouter');

    final getMe = overrides?.apiGetMe ?? (() => ApiService.getMe());
    final read = overrides?.storageRead ?? ((key) => _storage.read(key: key));
    final getUserProfile = overrides?.apiGetUserProfile ?? ((id) => ApiService.getUserProfile(id));
    final getInstructorMeOrNull =
        overrides?.apiGetInstructorMeOrNull ?? (() => ApiService.getInstructorMeOrNull());

    try {
      await getMe();
      setLastError(null);
    } catch (e) {
      lastRoutingError = e.toString();
      developer.log('[RoleRouter] ctx=$context auth/me failed → Login ($e)', name: 'RoleRouter');
      return LoginScreen.routeName;
    }

    final userId = await read('user_id');
    if (userId == null) {
      developer.log('[RoleRouter] ctx=$context missing user_id → Login', name: 'RoleRouter');
      return LoginScreen.routeName;
    }

    final profile = await getUserProfile(userId);
    final role = profile['role']?.toString().toUpperCase();
    developer.log('[RoleRouter] ctx=$context role(from users/$userId)=$role', name: 'RoleRouter');

    if (role == 'ADMIN') return AdminDashboardScreen.routeName;

    if (role == 'INSTRUCTOR') {
      final instructorProfile = await getInstructorMeOrNull();
      final isComplete = _isInstructorProfileComplete(instructorProfile);
      developer.log(
        '[RoleRouter] ctx=$context instructorProfile=${instructorProfile != null ? "present" : "null"} complete=$isComplete',
        name: 'RoleRouter',
      );

      if (!isComplete) {
        developer.log('[RoleRouter] ctx=$context → CompleteInstructorProfile', name: 'RoleRouter');
        return CompleteInstructorProfileScreen.routeName;
      }
      return InstructorDashboardScreen.routeName;
    }

    return HomeScreen.routeName;
  }

  static bool _isInstructorProfileComplete(Map<String, dynamic>? instructor) {
    if (instructor == null) return false;
    final license = instructor['licenseNumber']?.toString().trim();
    final exp = instructor['experienceYears'];
    final lat = instructor['lat'];
    final lng = instructor['lng'];
    final isListed = instructor['isListed'];

    final hasLicense = license != null && license.isNotEmpty;
    final hasExp = exp is num ? true : (int.tryParse(exp?.toString() ?? '') != null);
    final hasLatLng = (lat is num) && (lng is num);
    final hasIsListed = isListed is bool;

    return hasLicense && hasExp && hasLatLng && hasIsListed;
  }
}
```

### test/role_router_test.dart

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/screens/complete_instructor_profile_screen.dart';
import 'package:manejapp/screens/home_screen.dart';
import 'package:manejapp/screens/instructor_dashboard_screen.dart';
import 'package:manejapp/screens/login_screen.dart';
import 'package:manejapp/utils/role_router.dart';

void main() {
  group('RoleRouter', () {
    test('A: token null → Login', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (_) async => null,
      );
      final route = await RoleRouter.resolveInitialRoute(overrides: overrides);
      expect(route, LoginScreen.routeName);
    });

    test('B: token ok + role STUDENT → Home', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token' ? 'fake-token' : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'STUDENT'},
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, HomeScreen.routeName);
    });

    test('C: token ok + role INSTRUCTOR + incomplete → CompleteInstructorProfile', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token' ? 'fake-token' : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => {
          'licenseNumber': '123',
          'experienceYears': 1,
          'lat': null,
          'lng': null,
          'isListed': null,
        },
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, CompleteInstructorProfileScreen.routeName);
    });

    test('D: token ok + role INSTRUCTOR + complete → InstructorDashboard', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token' ? 'fake-token' : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => {
          'licenseNumber': '123',
          'experienceYears': 1,
          'lat': -34.6,
          'lng': -58.4,
          'isListed': true,
        },
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorDashboardScreen.routeName);
    });

    test('E: auth/me fails → Login', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token' ? 'fake-token' : (key == 'user_id' ? '1' : null),
        apiGetMe: () async => throw Exception('auth/me failed'),
        apiGetUserProfile: (_) async => {'role': 'STUDENT'},
        apiGetInstructorMeOrNull: () async => null,
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, LoginScreen.routeName);
    });

    test('F: JWT stale (DB role INSTRUCTOR) → INSTRUCTOR path', () async {
      final overrides = RoleRouterOverrides(
        storageRead: (key) async => key == 'auth_token' ? 'stale-jwt' : (key == 'user_id' ? '1' : null),
        apiGetMe: () async {},
        apiGetUserProfile: (_) async => {'role': 'INSTRUCTOR'},
        apiGetInstructorMeOrNull: () async => {
          'licenseNumber': '123',
          'experienceYears': 1,
          'lat': -34.6,
          'lng': -58.4,
          'isListed': true,
        },
      );
      final route = await RoleRouter.resolveRouteForCurrentUser(
        context: 'test',
        overrides: overrides,
      );
      expect(route, InstructorDashboardScreen.routeName);
    });
  });
}
```

### lib/screens/debug_routing_screen.dart

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';
import '../utils/role_router.dart';

/// Pantalla de observabilidad de ruteo (solo debug). Muestra token, user_id, rol desde DB, ruta resuelta y último error.
class DebugRoutingScreen extends StatefulWidget {
  static const routeName = '/debug_routing';

  const DebugRoutingScreen({super.key});

  @override
  State<DebugRoutingScreen> createState() => _DebugRoutingScreenState();
}

class _DebugRoutingScreenState extends State<DebugRoutingScreen> {
  static const _storage = FlutterSecureStorage();

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
          resolvedRoute = await RoleRouter.resolveRouteForCurrentUser(context: 'debug_screen');
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
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontFamily: 'monospace')),
        ],
      ),
    );
  }
}
```

### lib/main.dart (fragmentos relevantes)

- Import: `import 'package:flutter/foundation.dart' show kReleaseMode;`
- Import: `import 'package:manejapp/screens/debug_routing_screen.dart';`
- En `_checkSession` catch: `RoleRouter.setLastError(e.toString());`
- En `routes`: `if (!kReleaseMode) DebugRoutingScreen.routeName: (context) => const DebugRoutingScreen(),`

### lib/screens/settings_screen.dart (fragmentos relevantes)

- Import: `import 'package:flutter/foundation.dart' show kReleaseMode;`
- Import: `import 'package:manejapp/screens/debug_routing_screen.dart';`
- AppBar title envuelto en GestureDetector con onLongPress que navega a `DebugRoutingScreen.routeName` cuando `!kReleaseMode`.

---

**Resumen de archivos**

| Repo | Archivo | Acción |
|------|---------|--------|
| ManejApp | scripts/qa-verify-endpoints.js | Creado |
| ManejApp | docs/QA_ENDPOINTS_VERIFICATION.md | Creado |
| ManejApp | docs/ROUTING_QA_CHECKLIST.md | Creado |
| ManejApp | docs/QA_DUMP_FULL_FILES.md | Creado (este archivo) |
| ManejApp-frontend | lib/utils/role_router.dart | Modificado (DI + lastRoutingError) |
| ManejApp-frontend | test/role_router_test.dart | Creado |
| ManejApp-frontend | lib/screens/debug_routing_screen.dart | Creado |
| ManejApp-frontend | lib/main.dart | Modificado (setLastError, ruta debug, import) |
| ManejApp-frontend | lib/screens/settings_screen.dart | Modificado (long-press → debug) |

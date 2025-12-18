# Validación de Email - Guía para Flutter

Esta guía explica cómo implementar la validación de email en una app Flutter que se integre con el backend de ManejApp.

## 📋 Requisitos Previos

- Flutter SDK >= 3.0
- Paquetes: `http`, `url_launcher`, `uni_links`

## 🔧 Configuración

### 1. Agregar Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  url_launcher: ^6.1.10
  uni_links: ^0.5.1
```

### 2. Configurar Deep Links

#### Android (android/app/src/main/AndroidManifest.xml)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <activity android:name=".MainActivity">
            <intent-filter android:autoVerify="true">
                <action android:name="android.intent.action.VIEW" />
                <category android:name="android.intent.category.DEFAULT" />
                <category android:name="android.intent.category.BROWSABLE" />
                <data android:scheme="manejapp" />
            </intent-filter>
        </activity>
    </application>
</manifest>
```

#### iOS (ios/Runner/Info.plist)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <string>manejapp</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
```

## 🚀 Implementación

### 1. Servicio de API

```dart
class ApiService {
  static const String baseUrl = 'https://tu-api.com';

  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String surname,
    required String email,
    required String dni,
    required String password,
    required DateTime birthDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'surname': surname,
        'email': email,
        'dni': dni,
        'password': password,
        'birthDate': birthDate.toIso8601String(),
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error en registro: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/verify-email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error en verificación: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> resendVerification(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/resend-verification'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al reenviar: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error en login: ${response.body}');
    }
  }
}
```

### 2. Manejo de Deep Links

```dart
class DeepLinkHandler {
  static StreamSubscription? _sub;

  static void init(BuildContext context) {
    // Manejar deep link inicial
    _handleInitialUri(context);

    // Escuchar deep links entrantes
    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleUri(context, uri);
      }
    }, onError: (err) {
      print('Error handling deep link: $err');
    });
  }

  static void dispose() {
    _sub?.cancel();
  }

  static Future<void> _handleInitialUri(BuildContext context) async {
    try {
      final uri = await getInitialUri();
      if (uri != null) {
        _handleUri(context, uri);
      }
    } catch (e) {
      print('Error getting initial URI: $e');
    }
  }

  static void _handleUri(BuildContext context, Uri uri) {
    if (uri.scheme == 'manejapp' && uri.path == '/verify-email') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        // Navegar a pantalla de verificación
        Navigator.of(context).pushNamed(
          '/verify-email',
          arguments: token,
        );
      }
    }
  }
}
```

### 3. Pantalla de Registro

```dart
class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();

  String _name = '';
  String _surname = '';
  String _email = '';
  String _dni = '';
  String _password = '';
  DateTime _birthDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.registerUser(
        name: _name,
        surname: _surname,
        email: _email,
        dni: _dni,
        password: _password,
        birthDate: _birthDate,
      );

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registro exitoso. Revisa tu email para verificar tu cuenta.'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar a pantalla de verificación pendiente
      Navigator.of(context).pushNamed('/email-verification-pending', arguments: _email);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Registro')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                onChanged: (value) => _name = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Apellido'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                onChanged: (value) => _surname = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => !value!.contains('@') ? 'Email inválido' : null,
                onChanged: (value) => _email = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'DNI'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                onChanged: (value) => _dni = value,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Contraseña'),
                obscureText: true,
                validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                onChanged: (value) => _password = value,
              ),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading ? CircularProgressIndicator() : Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 4. Pantalla de Verificación de Email

```dart
class VerifyEmailScreen extends StatefulWidget {
  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _apiService = ApiService();
  bool _isLoading = false;
  String? _token;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _token = ModalRoute.of(context)!.settings.arguments as String?;
    if (_token != null) {
      _verifyEmail();
    }
  }

  Future<void> _verifyEmail() async {
    if (_token == null) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.verifyEmail(_token!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email verificado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Navegar al login
      Navigator.of(context).pushReplacementNamed('/login');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error en verificación: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verificar Email')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Verificando tu email...',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Si no se redirige automáticamente, intenta iniciar sesión.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }
}
```

### 5. Pantalla de Verificación Pendiente

```dart
class EmailVerificationPendingScreen extends StatefulWidget {
  @override
  _EmailVerificationPendingScreenState createState() => _EmailVerificationPendingScreenState();
}

class _EmailVerificationPendingScreenState extends State<EmailVerificationPendingScreen> {
  final _apiService = ApiService();
  String? _email;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)!.settings.arguments as String?;
  }

  Future<void> _resendVerification() async {
    if (_email == null) return;

    setState(() => _isLoading = true);

    try {
      await _apiService.resendVerification(_email!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Email de verificación reenviado'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verifica tu Email')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              'Revisa tu email y haz clic en el enlace de verificación.',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              '¿No recibiste el email?',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _resendVerification,
              child: _isLoading
                  ? CircularProgressIndicator()
                  : Text('Reenviar Email'),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
              child: Text('Ya verifiqué mi email'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6. Modificar main.dart

```dart
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    DeepLinkHandler.init(context);
  }

  @override
  void dispose() {
    DeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ManejApp',
      routes: {
        '/': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/verify-email': (context) => VerifyEmailScreen(),
        '/email-verification-pending': (context) => EmailVerificationPendingScreen(),
      },
    );
  }
}
```

## 🔄 Flujo Completo

1. **Usuario se registra** → Recibe email con deep link
2. **Hace clic en email** → Se abre la app (o navegador)
3. **App maneja deep link** → Navega a pantalla de verificación
4. **Verificación automática** → Cuenta activada
5. **Usuario puede hacer login**

## 🛠️ Manejo de Errores

- **Token expirado**: Mostrar mensaje y opción de reenviar
- **Token inválido**: Mostrar error y redirigir a login
- **Email ya verificado**: Redirigir directamente al login

## 📝 Notas Importantes

- Asegúrate de que el esquema `manejapp://` esté registrado en ambas plataformas
- Prueba los deep links en dispositivos reales
- Considera agregar un fallback para cuando la app no esté instalada
- Los tokens expiran en 24 horas según la configuración del backend
# Guía de Estilos y Componentes - ManejApp

## 🎨 Paleta de Colores

### Colores Principales
```dart
// Color primario de la marca
static const primaryColor = Color(0xFF003087);

// Estados
static const successColor = Colors.green;
static const errorColor = Colors.red;
static const warningColor = Colors.orange;
static const infoColor = Colors.blue;

// Neutrales
static const backgroundColor = Colors.white;
static const textPrimary = Colors.black87;
static const textSecondary = Colors.grey;
```

### Modo Oscuro
```dart
// Automáticamente generado por ThemeProvider
// Basado en seedColor: Color(0xFF003087)
```

---

## 📐 Espaciado

```dart
// Padding estándar
const smallPadding = 8.0;
const mediumPadding = 16.0;
const largePadding = 24.0;

// Márgenes entre elementos
const smallMargin = 8.0;
const mediumMargin = 12.0;
const largeMargin = 16.0;
```

---

## 🔤 Tipografía

### Tamaños de Texto
```dart
// Títulos
const titleLarge = 28.0;
const titleMedium = 24.0;
const titleSmall = 20.0;

// Cuerpo
const bodyLarge = 16.0;
const bodyMedium = 14.0;
const bodySmall = 12.0;

// Captions
const caption = 10.0;
```

### Pesos de Fuente
```dart
const regular = FontWeight.w400;
const medium = FontWeight.w500;
const semiBold = FontWeight.w600;
const bold = FontWeight.w700;
```

---

## 🧩 Componentes Reutilizables

### 1. Botones

#### Botón Primario
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF003087),
    foregroundColor: Colors.white,
    padding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: const Text('Texto del Botón'),
)
```

#### Botón Secundario
```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: const Color(0xFF003087),
    side: const BorderSide(color: Color(0xFF003087)),
    padding: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  child: const Text('Texto del Botón'),
)
```

#### Botón de Texto
```dart
TextButton(
  onPressed: () {},
  child: const Text('Texto del Botón'),
)
```

---

### 2. Campos de Texto

#### TextField Estándar
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Label',
    hintText: 'Hint text',
    prefixIcon: const Icon(Icons.email),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    filled: true,
  ),
)
```

#### TextField con Validación
```dart
TextFormField(
  validator: Validators.email,
  decoration: InputDecoration(
    labelText: 'Email',
    prefixIcon: const Icon(Icons.email),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

---

### 3. Cards

#### Card Estándar
```dart
Card(
  margin: const EdgeInsets.all(16),
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        // Contenido
      ],
    ),
  ),
)
```

#### Card con Acción
```dart
Card(
  child: InkWell(
    onTap: () {},
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Contenido
        ],
      ),
    ),
  ),
)
```

---

### 4. Listas

#### ListTile Estándar
```dart
ListTile(
  leading: CircleAvatar(
    backgroundColor: const Color(0xFF003087),
    child: const Icon(Icons.person, color: Colors.white),
  ),
  title: const Text('Título'),
  subtitle: const Text('Subtítulo'),
  trailing: const Icon(Icons.arrow_forward_ios),
  onTap: () {},
)
```

#### Lista con Skeleton Loader
```dart
isLoading
  ? const ListSkeletonLoader()
  : ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return ListTile(/* ... */);
      },
    )
```

---

### 5. Diálogos

#### Diálogo de Confirmación
```dart
final result = await ConfirmationDialog.show(
  context,
  title: 'Título',
  message: 'Mensaje de confirmación',
  confirmText: 'Confirmar',
  cancelText: 'Cancelar',
);

if (result == true) {
  // Usuario confirmó
}
```

#### Diálogo Personalizado
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Título'),
    content: const Text('Contenido'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
    ],
  ),
)
```

---

### 6. SnackBars

#### SnackBar de Error
```dart
ErrorMessage.show(context, 'Mensaje de error');
```

#### SnackBar de Éxito
```dart
ErrorMessage.showSuccess(context, 'Operación exitosa');
```

#### SnackBar Personalizado
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: const Text('Mensaje'),
    backgroundColor: Colors.blue,
    behavior: SnackBarBehavior.floating,
    action: SnackBarAction(
      label: 'Acción',
      onPressed: () {},
    ),
  ),
)
```

---

### 7. AppBar

#### AppBar Estándar
```dart
AppBar(
  title: const Text('Título'),
  backgroundColor: const Color(0xFF003087),
  foregroundColor: Colors.white,
  elevation: 0,
)
```

#### AppBar con Acciones
```dart
AppBar(
  title: const Text('Título'),
  backgroundColor: const Color(0xFF003087),
  foregroundColor: Colors.white,
  actions: [
    IconButton(
      icon: const Icon(Icons.search),
      onPressed: () {},
    ),
    IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () {},
    ),
  ],
)
```

---

### 8. Bottom Navigation

```dart
BottomNavigationBar(
  currentIndex: _selectedIndex,
  onTap: (index) => setState(() => _selectedIndex = index),
  selectedItemColor: const Color(0xFF003087),
  unselectedItemColor: Colors.grey,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.home),
      label: 'Inicio',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.calendar_today),
      label: 'Clases',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat),
      label: 'Mensajes',
    ),
  ],
)
```

---

### 9. Skeleton Loaders

#### Skeleton Simple
```dart
SkeletonLoader(
  width: 100,
  height: 20,
  borderRadius: BorderRadius.circular(4),
)
```

#### Skeleton de Lista
```dart
const ListSkeletonLoader(itemCount: 5)
```

#### Skeleton de Card
```dart
const CardSkeletonLoader()
```

---

### 10. Badges

#### Badge de Notificaciones
```dart
Badge(
  label: Text('3'),
  child: const Icon(Icons.notifications),
)
```

#### Badge Personalizado
```dart
Stack(
  children: [
    const Icon(Icons.chat),
    Positioned(
      right: 0,
      top: 0,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: const Text(
          '5',
          style: TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    ),
  ],
)
```

---

## 🎭 Animaciones

### Transición de Página
```dart
Navigator.push(
  context,
  PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => NextScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  ),
)
```

### Animación de Lista
```dart
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

AnimationLimiter(
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      return AnimationConfiguration.staggeredList(
        position: index,
        duration: const Duration(milliseconds: 375),
        child: SlideAnimation(
          verticalOffset: 50.0,
          child: FadeInAnimation(
            child: ListTile(/* ... */),
          ),
        ),
      );
    },
  ),
)
```

---

## 📱 Responsive Design

### Breakpoints
```dart
const mobileBreakpoint = 600;
const tabletBreakpoint = 900;
const desktopBreakpoint = 1200;
```

### Uso
```dart
final width = MediaQuery.of(context).size.width;

if (width < mobileBreakpoint) {
  // Layout móvil
} else if (width < tabletBreakpoint) {
  // Layout tablet
} else {
  // Layout desktop
}
```

---

## ✅ Mejores Prácticas

### 1. Consistencia
- Usar siempre los mismos colores, espaciados y componentes
- Mantener la misma estructura en pantallas similares

### 2. Accesibilidad
- Tamaños de texto legibles (mínimo 14px)
- Contraste adecuado entre texto y fondo
- Áreas táctiles de al menos 48x48 px

### 3. Performance
- Usar const constructors cuando sea posible
- Implementar lazy loading en listas largas
- Cachear imágenes con CachedNetworkImage

### 4. Feedback Visual
- Mostrar loading indicators durante operaciones
- Confirmar acciones destructivas
- Mostrar mensajes de éxito/error claros

### 5. Navegación
- Mantener jerarquía clara
- Usar back button consistentemente
- Indicar posición actual en navegación

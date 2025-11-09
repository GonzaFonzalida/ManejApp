# 🚗 ManejApp - Sistema de Gestión para Escuelas de Manejo

<div align="center">

![ManejApp](https://img.shields.io/badge/ManejApp-v1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.8.1-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange?logo=firebase)
![License](https://img.shields.io/badge/License-Proprietary-red)

**La solución completa para gestionar tu escuela de manejo** 🎓

[Características](#-características) • [Instalación](#-instalación) • [Uso](#-uso) • [Documentación](#-documentación)

</div>

---

## 📋 Descripción

ManejApp es una aplicación móvil completa desarrollada en Flutter que permite a escuelas de manejo gestionar estudiantes, instructores, clases y pagos de manera eficiente. Con integración de MercadoPago para pagos seguros y Firebase para notificaciones en tiempo real.

## ✨ Características

### 🎯 Funcionalidades Principales

#### Para Estudiantes
- 📱 Dashboard personalizado con estadísticas
- 🔍 Búsqueda y reserva de clases con instructores
- 📅 Gestión de horarios y clases
- ⭐ Sistema de calificaciones y feedback
- 💳 Pagos seguros con MercadoPago
- 💬 Chat directo con instructores
- 👤 Perfil editable

#### Para Instructores
- 📊 Dashboard con métricas del día
- 🕐 Gestión de horarios disponibles
- ✅ Completar clases con notas
- 👥 Ver estudiantes asignados
- 💬 Chat con estudiantes
- 💼 Perfil profesional editable
- 💰 Configuración de tarifas

#### Para Administradores
- 📈 Dashboard con estadísticas generales
- 👥 Gestión completa de usuarios
- 📊 Reportes con gráficos interactivos
- 💵 Análisis de ingresos
- ⚙️ Configuración del sistema

### 🔔 Notificaciones Push
- Nueva clase reservada
- Recordatorio de clase (1 hora antes)
- Clase completada
- Pago confirmado
- Nuevos mensajes de chat

### 💳 Sistema de Pagos
- Integración completa con MercadoPago
- Pagos seguros y encriptados
- Webhooks para actualización automática
- Historial de transacciones
- Múltiples métodos de pago

### 💬 Sistema de Chat
- Mensajería en tiempo real
- Interfaz moderna
- Historial de conversaciones
- Notificaciones de mensajes

## 🛠️ Tecnologías

- **Frontend**: Flutter 3.8.1
- **Backend**: Node.js + Express + TypeScript
- **Base de Datos**: PostgreSQL con Prisma ORM
- **Notificaciones**: Firebase Cloud Messaging
- **Pagos**: MercadoPago API
- **Mapas**: Google Maps / OpenStreetMap
- **Almacenamiento**: Flutter Secure Storage

## 📦 Instalación

### Requisitos Previos
```bash
- Flutter SDK 3.8.1+
- Android Studio / VS Code
- Cuenta de Firebase
- Cuenta de MercadoPago
```

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/tu-usuario/manejapp.git
cd manejapp
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase**
- Crear proyecto en Firebase Console
- Descargar `google-services.json`
- Colocar en `android/app/`

4. **Configurar Backend**
- Actualizar URL en `lib/services/api_service.dart`
- Configurar variables de entorno

5. **Ejecutar la app**
```bash
flutter run
```

Para más detalles, ver [SETUP.md](SETUP.md)

## 🚀 Uso

### Primera Vez
1. Abre la app y completa el onboarding
2. Regístrate como estudiante o instructor
3. Completa tu perfil
4. ¡Comienza a usar ManejApp!

### Como Estudiante
1. Busca instructores disponibles
2. Reserva una clase
3. Realiza el pago
4. Asiste a tu clase
5. Califica tu experiencia

### Como Instructor
1. Configura tus horarios disponibles
2. Espera reservas de estudiantes
3. Imparte tus clases
4. Completa las clases con notas
5. Recibe tus pagos

### Como Administrador
1. Accede al panel administrativo
2. Gestiona usuarios y clases
3. Revisa reportes y estadísticas
4. Configura el sistema

## 📱 Capturas de Pantalla

```
[Aquí irían las capturas de pantalla]
```

## 🏗️ Arquitectura

```
lib/
├── controllers/      # Lógica de negocio
├── models/          # Modelos de datos
├── screens/         # Pantallas UI
│   ├── admin/      # Pantallas admin
│   ├── instructor/ # Pantallas instructor
│   └── student/    # Pantallas estudiante
├── services/        # Servicios (API, Firebase, etc)
├── widgets/         # Widgets reutilizables
└── main.dart       # Punto de entrada
```

## 📚 Documentación

- [Guía de Instalación](SETUP.md)
- [Changelog](CHANGELOG.md)
- [API Documentation](docs/API_INTEGRATION.md)
- [Autenticación](docs/AUTHENTICATION.md)
- [Sistema de Pagos](docs/PAYMENT_INTEGRATION.md)
- [Sistema de Horarios](docs/SCHEDULE_SYSTEM.md)

## 🧪 Testing

```bash
# Ejecutar tests
flutter test

# Ejecutar tests con coverage
flutter test --coverage
```

## 🔒 Seguridad

- Autenticación JWT con refresh tokens
- Almacenamiento seguro de credenciales
- Encriptación de datos sensibles
- Validación de inputs
- Protección contra XSS y SQL Injection
- HTTPS obligatorio

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📝 Roadmap

- [x] Sistema de autenticación
- [x] Gestión de clases
- [x] Sistema de pagos
- [x] Notificaciones push
- [x] Chat en tiempo real
- [x] Panel administrativo
- [ ] Modo oscuro
- [ ] Soporte multiidioma
- [ ] App iOS
- [ ] Web app

## 🐛 Reportar Bugs

Si encuentras un bug, por favor abre un issue con:
- Descripción del problema
- Pasos para reproducir
- Comportamiento esperado
- Screenshots (si aplica)
- Versión de la app

## 📄 Licencia

© 2024 ManejApp. Todos los derechos reservados.

## 👥 Equipo

- **Desarrollo**: Tu Nombre
- **Diseño**: Tu Nombre
- **Backend**: Tu Nombre

## 📞 Contacto

- Email: soporte@manejapp.com
- Website: https://manejapp.com
- Twitter: [@manejapp](https://twitter.com/manejapp)

## 🙏 Agradecimientos

- Flutter Team
- Firebase
- MercadoPago
- Comunidad Open Source

---

<div align="center">

**Hecho con ❤️ en Argentina**

[⬆ Volver arriba](#-manejapp---sistema-de-gestión-para-escuelas-de-manejo)

</div>

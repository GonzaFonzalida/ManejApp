import 'package:flutter/widgets.dart';

/// Refresca datos al volver a foreground, con debounce para evitar recargas en bucle.
///
/// Usar junto con [WidgetsBindingObserver]:
/// `class _X extends State<X> with WidgetsBindingObserver, AppResumeRefreshMixin`
mixin AppResumeRefreshMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  DateTime? _lastResumeRefresh;
  static const _minInterval = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  void _onAppResumed() {
    final now = DateTime.now();
    if (_lastResumeRefresh != null &&
        now.difference(_lastResumeRefresh!) < _minInterval) {
      return;
    }
    _lastResumeRefresh = now;
    refreshOnAppResume();
  }

  /// Implementar recarga silenciosa de datos críticos (sin skeleton completo si aplica).
  void refreshOnAppResume();
}

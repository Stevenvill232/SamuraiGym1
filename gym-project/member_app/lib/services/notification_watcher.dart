import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/member_providers.dart';
import 'local_notification_service.dart';

/// Envuelve las pantallas autenticadas del miembro. Mientras la app está
/// abierta (o recién enviada a segundo plano) consulta cada 30 segundos al
/// servidor si hay avisos nuevos y los muestra como notificación del sistema;
/// también consulta al volver a abrir la app.
class NotificationWatcher extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationWatcher({super.key, required this.child});

  @override
  ConsumerState<NotificationWatcher> createState() =>
      _NotificationWatcherState();
}

class _NotificationWatcherState extends ConsumerState<NotificationWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _consultando = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      await LocalNotificationService.instance.init();
      await LocalNotificationService.instance.pedirPermiso();
    } catch (_) {
      // Si el sistema de notificaciones falla, la campana sigue funcionando.
    }
    if (!mounted) return;
    _consultar();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _consultar());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _consultar();
  }

  Future<void> _consultar() async {
    if (_consultando) return;
    _consultando = true;
    try {
      final nuevas = await ref.read(memberRepositoryProvider).reclamarAvisos();
      for (final n in nuevas) {
        await LocalNotificationService.instance.mostrar(n);
      }
      if (nuevas.isNotEmpty && mounted) {
        ref.invalidate(unreadCountProvider);
        ref.invalidate(notificationsProvider);
      }
    } catch (_) {
      // Sin conexión o error momentáneo: se reintenta en la próxima vuelta.
    } finally {
      _consultando = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

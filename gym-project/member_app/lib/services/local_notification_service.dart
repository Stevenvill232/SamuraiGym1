import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/member_models.dart';

/// Muestra notificaciones REALES del sistema (banner y bandeja del teléfono).
/// Solo en Android e iOS; en cualquier otra plataforma no hace nada.
class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _listo = false;

  bool get _soportado =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> init() async {
    if (_listo || !_soportado) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _listo = true;
  }

  /// Android 13+ e iOS piden permiso al usuario (aparece un cuadro de diálogo
  /// la primera vez). Si lo rechaza, solo queda la campana dentro de la app.
  Future<void> pedirPermiso() async {
    if (!_soportado) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> mostrar(Notificacion n) async {
    if (!_listo) return;
    const detalles = NotificationDetails(
      android: AndroidNotificationDetails(
        'avisos_gimnasio',
        'Avisos del gimnasio',
        channelDescription: 'Vencimientos de plan, pagos y tiquetera',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    // El id del aviso es un UUID: se convierte a un entero positivo estable.
    await _plugin.show(n.id.hashCode & 0x7fffffff, n.titulo, n.mensaje, detalles);
  }
}

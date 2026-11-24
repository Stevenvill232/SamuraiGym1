import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import '../data/member_models.dart';
import 'auth_provider.dart';

/// Todas las llamadas de la app de miembros al backend, en un solo lugar.
/// Los errores llegan como [ApiException] con mensaje listo para mostrar.
class MemberRepository {
  final ApiClient _api;
  MemberRepository(this._api);

  Future<MemberProfile> perfil() async =>
      MemberProfile.fromJson(await _api.get('/profile'));

  Future<void> actualizarPerfil(Map<String, dynamic> cambios) async {
    await _api.patch('/profile', body: cambios);
  }

  Future<void> guardarAlimentacion(PerfilAlimentacion p) async {
    await _api.put('/profile/nutrition', body: p.toJson());
  }

  Future<void> guardarEntrenamiento(PerfilEntrenamiento p) async {
    await _api.put('/profile/training', body: p.toJson());
  }

  Future<void> cambiarPassword(String actual, String nueva) async {
    await _api.patch('/auth/password', body: {'actual': actual, 'nueva': nueva});
  }

  Future<MemberDashboard> dashboard() async =>
      MemberDashboard.fromJson(await _api.get('/dashboard/miembro'));

  Future<List<PlanDetalle>> planes() async {
    final data = await _api.getList('/plans/me');
    return data
        .map((j) => PlanDetalle.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<List<RegistroFisico>> progreso() async {
    final data = await _api.getList('/progress');
    return data
        .map((j) =>
            RegistroFisico.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<void> registrarMedidas({
    required double peso,
    required double estatura,
    required DateTime fecha,
  }) async {
    await _api.post('/progress', body: {
      'peso': peso,
      'estatura': estatura,
      'fecha': fecha.toUtc().toIso8601String(),
    });
  }

  Future<void> eliminarRegistro(String id) async {
    await _api.delete('/progress/$id');
  }

  Future<AppSettings> settings() async =>
      AppSettings.fromJson(await _api.get('/settings'));

  Future<List<Notificacion>> notificaciones() async {
    final data = await _api.getList('/notifications/me');
    return data
        .map((j) => Notificacion.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  /// Avisos que el teléfono aún no mostró como notificación del sistema (el
  /// servidor los marca como entregados al reclamarlos, así no se repiten).
  Future<List<Notificacion>> reclamarAvisos() async {
    final d = await _api.post('/notifications/me/claim');
    final lista = d['data'];
    if (lista is! List) return const [];
    return lista
        .map((j) => Notificacion.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  // ---- Asistente de IA (las llamadas pueden tardar: se amplía el tiempo límite)
  static const _esperaIA = Duration(seconds: 100);

  Future<RutinaIA> generarRutina({
    String? enfoque,
    String? lugar,
    String? intensidad,
    int? minutos,
    String? notas,
  }) async {
    final d = await _api.post('/ai/routine', timeout: _esperaIA, body: {
      if (enfoque != null) 'enfoque': enfoque,
      if (lugar != null) 'lugar': lugar,
      if (intensidad != null) 'intensidad': intensidad,
      if (minutos != null) 'minutos': minutos,
      if (notas != null && notas.isNotEmpty) 'notas': notas,
    });
    return RutinaIA.fromJson(d);
  }

  Future<List<RutinaIA>> rutinas() async {
    final data = await _api.getList('/ai/routines');
    return data
        .map((j) => RutinaIA.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<ComidaIA> generarComida(String tipoComida, {String? notas}) async {
    final d = await _api.post('/ai/nutrition', timeout: _esperaIA, body: {
      'tipoComida': tipoComida,
      if (notas != null && notas.isNotEmpty) 'notas': notas,
    });
    return ComidaIA.fromJson(d);
  }

  Future<List<ComidaIA>> comidas() async {
    final data = await _api.getList('/ai/nutrition');
    return data
        .map((j) => ComidaIA.fromJson(Map<String, dynamic>.from(j as Map)))
        .toList();
  }

  Future<String> chat(
      String mensaje, List<({String rol, String texto})> historial) async {
    final d = await _api.post('/ai/chat', timeout: _esperaIA, body: {
      'mensaje': mensaje,
      if (historial.isNotEmpty)
        'historial': [
          for (final t in historial) {'rol': t.rol, 'texto': t.texto},
        ],
    });
    return (d['respuesta'] as String?) ?? '';
  }

  Future<int> noLeidas() async {
    final d = await _api.get('/notifications/me/unread-count');
    return (d['count'] as num?)?.toInt() ?? 0;
  }

  Future<void> marcarNotificacionLeida(String id) async {
    await _api.patch('/notifications/$id/read');
  }

  Future<void> marcarTodasLeidas() async {
    await _api.patch('/notifications/me/read-all');
  }
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.watch(apiClientProvider));
});

// autoDispose: cada vez que se entra a una pantalla se piden datos frescos.
final profileProvider = FutureProvider.autoDispose<MemberProfile>(
    (ref) => ref.watch(memberRepositoryProvider).perfil());

final memberDashboardProvider = FutureProvider.autoDispose<MemberDashboard>(
    (ref) => ref.watch(memberRepositoryProvider).dashboard());

final memberPlansProvider = FutureProvider.autoDispose<List<PlanDetalle>>(
    (ref) => ref.watch(memberRepositoryProvider).planes());

final progressProvider = FutureProvider.autoDispose<List<RegistroFisico>>(
    (ref) => ref.watch(memberRepositoryProvider).progreso());

/// Nombre y teléfono del gimnasio (para el mensaje de "cómo renovar").
final gymSettingsProvider = FutureProvider.autoDispose<AppSettings>(
    (ref) => ref.watch(memberRepositoryProvider).settings());

final notificationsProvider = FutureProvider.autoDispose<List<Notificacion>>(
    (ref) => ref.watch(memberRepositoryProvider).notificaciones());

/// Cantidad de avisos sin leer (para el contador de la campana).
final unreadCountProvider = FutureProvider.autoDispose<int>(
    (ref) => ref.watch(memberRepositoryProvider).noLeidas());

final rutinasProvider = FutureProvider.autoDispose<List<RutinaIA>>(
    (ref) => ref.watch(memberRepositoryProvider).rutinas());

final comidasProvider = FutureProvider.autoDispose<List<ComidaIA>>(
    (ref) => ref.watch(memberRepositoryProvider).comidas());

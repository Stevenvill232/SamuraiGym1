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

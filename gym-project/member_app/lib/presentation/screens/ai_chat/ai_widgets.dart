import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_models/shared_models.dart';
import '../../../data/member_models.dart';

String etiquetaTipoComida(String t) => switch (t) {
      'DESAYUNO' => 'Desayuno',
      'MEDIA_MANANA' => 'Media mañana',
      'ALMUERZO' => 'Almuerzo',
      'MERIENDA' => 'Merienda',
      'CENA' => 'Cena',
      _ => t,
    };

String etiquetaIntensidad(String? i) => switch (i) {
      'SUAVE' => 'suave',
      'ALTA' => 'alta',
      _ => 'media',
    };

String cuandoCorto(DateTime f) {
  final l = f.toLocal();
  final h = DateTime.now();
  final hora =
      '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  final hoy = l.year == h.year && l.month == h.month && l.day == h.day;
  return hoy ? 'Hoy $hora' : '${FormatoFecha.corta(f)} $hora';
}

/// Chips de selección única con título.
class ChipsSeleccion<T> extends StatelessWidget {
  final String titulo;
  final List<(String, T)> opciones;
  final T valor;
  final ValueChanged<T> onChanged;
  const ChipsSeleccion({
    super.key,
    required this.titulo,
    required this.opciones,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final o in opciones)
              ChoiceChip(
                label: Text(o.$1),
                selected: valor == o.$2,
                onSelected: (_) => onChanged(o.$2),
              ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
  }
}

/// Aviso cuando el perfil está incompleto, con acceso directo a completarlo.
class PerfilIncompletoBanner extends StatelessWidget {
  final String texto;
  final String ruta;
  const PerfilIncompletoBanner({super.key, required this.texto, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.estadoPorVencer.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.estadoPorVencer),
          const SizedBox(width: 12),
          Expanded(child: Text(texto)),
          TextButton(
            onPressed: () => context.push(ruta),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }
}

class AvisoIA extends StatelessWidget {
  const AvisoIA({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Sugerencia generada por IA. No reemplaza la evaluación de un profesional de la salud.',
      style: Theme.of(context)
          .textTheme
          .bodySmall
          ?.copyWith(color: AppColors.textMuted, fontStyle: FontStyle.italic),
    );
  }
}

class _Bloque extends StatelessWidget {
  final String titulo;
  final List<String> items;
  const _Bloque(this.titulo, this.items);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6, right: 8),
                    child: Icon(Icons.circle, size: 5, color: AppColors.textMuted),
                  ),
                  Expanded(child: Text(i)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class RutinaView extends StatelessWidget {
  final RutinaIA rutina;
  const RutinaView({super.key, required this.rutina});

  String _detalle(EjercicioIA e) {
    final partes = <String>[
      if (e.series != null) '${e.series} series',
      if (e.repeticiones.isNotEmpty) '${e.repeticiones} rep.',
      if (e.descanso.isNotEmpty) 'descanso ${e.descanso}',
    ];
    return partes.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: AppColors.textMuted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rutina.duracionMin != null)
          Row(children: [
            const Icon(Icons.timer_outlined, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('${rutina.duracionMin} min aprox.'),
          ]),
        if (rutina.calentamiento.isNotEmpty)
          _Bloque('Calentamiento', rutina.calentamiento),
        const SizedBox(height: 14),
        Text('Ejercicios', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        for (var i = 0; i < rutina.ejercicios.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: AppColors.ember.withValues(alpha: 0.12),
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ember,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rutina.ejercicios[i].nombre,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (_detalle(rutina.ejercicios[i]).isNotEmpty)
                        Text(_detalle(rutina.ejercicios[i]), style: muted),
                      if (rutina.ejercicios[i].notas != null &&
                          rutina.ejercicios[i].notas!.isNotEmpty)
                        Text(rutina.ejercicios[i].notas!, style: muted),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (rutina.enfriamiento.isNotEmpty)
          _Bloque('Enfriamiento', rutina.enfriamiento),
        if (rutina.recomendaciones.isNotEmpty)
          _Bloque('Recomendaciones', rutina.recomendaciones),
        const SizedBox(height: 14),
        const AvisoIA(),
      ],
    );
  }
}

class ComidaView extends StatelessWidget {
  final ComidaIA comida;
  const ComidaView({super.key, required this.comida});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comida.caloriasAprox != null)
          Row(children: [
            const Icon(Icons.local_fire_department_outlined,
                size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('${comida.caloriasAprox} kcal aprox.'),
          ]),
        _Bloque('Qué comer', [
          for (final a in comida.alimentos)
            a.porcion.isEmpty ? a.nombre : '${a.nombre} — ${a.porcion}',
        ]),
        if (comida.alternativas.isNotEmpty)
          _Bloque('Alternativas', comida.alternativas),
        if (comida.recomendaciones.isNotEmpty)
          _Bloque('Recomendaciones', comida.recomendaciones),
        const SizedBox(height: 14),
        const AvisoIA(),
      ],
    );
  }
}

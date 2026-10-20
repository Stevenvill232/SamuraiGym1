import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Sistema de diseño único para las dos apps (regla del proyecto: "utilizar
/// colores y estilos consistentes en ambas aplicaciones para que pertenezcan
/// al mismo sistema").
///
/// Dirección visual: panel de control atlético — un lienzo claro y sobrio
/// para trabajar con datos (formularios, tablas, contabilidad) acentuado con
/// "ember", un naranja-rojo de alta energía que evoca esfuerzo físico, y una
/// barra de navegación oscura tipo "grafito" que ancla la identidad de marca
/// en ambas apps sin sacrificar la legibilidad de los datos.
class AppColors {
  AppColors._();

  // Marca
  static const ember = Color(0xFFE8542A); // acción primaria / marca
  static const emberDark = Color(0xFFC23F1B);
  static const graphite = Color(0xFF1B1F23); // sidebar / nav / texto principal
  static const graphiteSoft = Color(0xFF2A2F35);

  // Superficies
  static const background = Color(0xFFF5F6F4);
  static const surface = Color(0xFFFFFFFF);
  static const borderSubtle = Color(0xFFE4E5E1);

  // Texto
  static const textPrimary = Color(0xFF1B1F23);
  static const textMuted = Color(0xFF6B7280);

  // Estados de negocio (planes) — usados también fuera del Dashboard.
  static const estadoActivo = Color(0xFF1F7A4D);
  static const estadoPorVencer = Color(0xFFFB8C00);
  static const estadoVencido = Color(0xFFE53935);
  static const estadoAgotado = Color(0xFF6B7280);

  /// Colores EXACTOS pedidos por la regla de negocio de alertas de
  /// vencimiento del Dashboard: naranja (2 días), rojo (1 día), gris
  /// (vencido hoy o hace 1 día). No confundir con `estadoPorVencer` /
  /// `estadoVencido`, que son de uso más general.
  static const alertaDosDias = Color(0xFFFB8C00);
  static const alertaUnDia = Color(0xFFE53935);
  static const alertaVencidaReciente = Color(0xFF9E9E9E);
}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final textTheme = _buildTextTheme();

    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.ember,
      brightness: Brightness.light,
      primary: AppColors.ember,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.ember, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ember,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.borderSubtle),
    );
  }

  static TextTheme _buildTextTheme() {
    // Space Grotesk para títulos y cifras (dashboard, KPIs): tiene carácter
    // geométrico que distingue números grandes sin perder seriedad.
    // Inter para texto de cuerpo: máxima legibilidad en formularios y tablas.
    final display = GoogleFonts.spaceGroteskTextTheme();
    final body = GoogleFonts.interTextTheme();

    return body.copyWith(
      displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w600),
      displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
      headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
      headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  /// Color según el estado de un plan — usar en badges/chips en toda la app.
  static Color colorEstadoPlan(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return AppColors.estadoActivo;
      case 'POR_VENCER':
        return AppColors.estadoPorVencer;
      case 'VENCIDO':
        return AppColors.estadoVencido;
      case 'AGOTADO':
        return AppColors.estadoAgotado;
      default:
        return AppColors.textMuted;
    }
  }
}

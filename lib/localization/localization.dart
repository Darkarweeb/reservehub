
/// ReserveHub — Sistema de Localización
///
/// ARQUITECTURA
/// ─────────────────────────────────────────────────────────────────────────────
/// AppStrings es la ÚNICA fuente de verdad para todo el texto de la plataforma.
///
/// IDIOMA PREDETERMINADO: Español (es) — ReserveHub 1.0.0
///
/// FASES FUTURAS:
///   Fase L2 — Inglés (en):
///     Crear AppStringsEn con los mismos identificadores que AppStrings.
///     Inyectar vía LocalizationProvider o flutter_localizations.
///
///   Fase L3 — Portugués (pt):
///     Crear AppStringsPt con los mismos identificadores que AppStrings.
///
///   Fase L4 — i18n completo:
///     Migrar a flutter_localizations + archivos ARB si se requiere
///     soporte dinámico de idioma en tiempo de ejecución.
///
/// USO:
///
///   Text(AppStrings.signIn)
///
/// REGLAS:
///   - No codificar texto de UI directamente en widgets.
///   - No traducir contenido generado por el usuario.
///   - No traducir identificadores Dart, tablas de BD o nombres de RPC.
/// ─────────────────────────────────────────────────────────────────────────────
library;

export 'app_strings.dart';

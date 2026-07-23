import 'package:flutter/material.dart';
import '../utils/constants.dart';

enum ToastTipo { success, error, warning, info }

/// Replica los toasts del screenshot "Notificaciones":
/// Etapa completada, Error al guardar, Stock por debajo, Sesión iniciada,
/// Lote completado (con acción), Sin conexión (con reintentar), Guardando.
class OsatToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastTipo tipo = ToastTipo.info,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    late Color bg, border, iconColor;
    late IconData icon;

    switch (tipo) {
      case ToastTipo.success:
        bg = AppColors.badgeGreenBg;
        border = AppColors.green;
        iconColor = AppColors.green;
        icon = Icons.check_circle;
        break;
      case ToastTipo.error:
        bg = AppColors.badgeRedBg;
        border = AppColors.red;
        iconColor = AppColors.red;
        icon = Icons.cancel;
        break;
      case ToastTipo.warning:
        bg = AppColors.badgeYellowBg;
        border = AppColors.gold;
        iconColor = AppColors.gold;
        icon = Icons.warning_rounded;
        break;
      case ToastTipo.info:
        bg = AppColors.badgeBlueBg;
        border = AppColors.turquoise;
        iconColor = AppColors.turquoise;
        icon = Icons.info_rounded;
        break;
    }

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: border, width: 1.2),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 8, offset: Offset(0, 2))
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(message,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textDark)),
                ),
                if (actionLabel != null)
                  TextButton(
                    onPressed: () {
                      entry.remove();
                      onAction?.call();
                    },
                    child: Text(actionLabel,
                        style: const TextStyle(
                            color: AppColors.turquoise,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () {
      if (entry.mounted) entry.remove();
    });
  }
}

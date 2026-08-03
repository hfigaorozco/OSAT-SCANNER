import 'package:flutter/material.dart';
import '../utils/constants.dart';

class OsatBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int alertasNoLeidas;

  const OsatBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.alertasNoLeidas = 0,
  });

  @override
  Widget build(BuildContext context) {
    final s = AppScale.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgTopbar,
        border: Border(top: BorderSide(color: Color(0xFF2E3D52), width: 1)),
      ),
      padding: EdgeInsets.symmetric(vertical: s.sp(8)),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              s: s,
              icon: Icons.home_rounded,
              label: 'Inicio',
              selected: currentIndex == 0,
              onTap: () => onTap(0),
            ),
            _NavItem(
              s: s,
              icon: Icons.qr_code_scanner_rounded,
              label: 'Escanear',
              selected: currentIndex == 1,
              onTap: () => onTap(1),
            ),
            _NavItem(
              s: s,
              icon: Icons.notifications_rounded,
              label: 'Alertas',
              selected: currentIndex == 2,
              onTap: () => onTap(2),
              badgeCount: alertasNoLeidas,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppScale s;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.s,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.green : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: s.sp(14), vertical: s.sp(4)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: s.ic(24)),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: EdgeInsets.all(s.sp(3)),
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          BoxConstraints(minWidth: s.sp(14), minHeight: s.sp(14)),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: s.f(8),
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: s.sp(3)),
            Text(label, style: TextStyle(color: color, fontSize: s.f(11))),
          ],
        ),
      ),
    );
  }
}

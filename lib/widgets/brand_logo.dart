import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final bool isLight;
  final double iconSize;
  final double fontSize;
  final bool showBadge;

  const BrandLogo({
    super.key,
    this.isLight = false,
    this.iconSize = 36,
    this.fontSize = 20,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: iconSize + 8,
          height: iconSize + 8,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryBlue, Color(0xFF1D4ED8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.hub_rounded,
            color: Colors.white,
            size: iconSize * 0.65,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Uni',
                  style: TextStyle(
                    color: isLight ? Colors.white : AppColors.primaryNavy,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Flow',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            if (showBadge)
              Text(
                'CAMPUS JOURNEY ENGINE',
                style: TextStyle(
                  color: isLight ? Colors.white70 : AppColors.textMuted,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

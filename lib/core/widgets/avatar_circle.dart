import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';

/// Crown Cuts — Circular Avatar with Initials
class AvatarCircle extends StatelessWidget {
  final String name;
  final double radius;
  final String? imageUrl;
  final Color? backgroundColor;
  final bool showGoldRing;

  const AvatarCircle({
    super.key,
    required this.name,
    this.radius = 24,
    this.imageUrl,
    this.backgroundColor,
    this.showGoldRing = false,
  });

  Color _getColor() {
    if (backgroundColor != null) return backgroundColor!;
    final colors = AppColors.avatarColors;
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    if (name.length >= 2) return name.substring(0, 2).toUpperCase();
    return name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final avatarColor = imageUrl == null ? _getColor() : c.surface2;

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundColor: avatarColor,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              _initials,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: radius * 0.58,
              ),
            )
          : null,
    );

    if (showGoldRing) {
      avatar = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFC9A84C), Color(0xFFE8B84B), Color(0xFFC9A84C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: CircleAvatar(
          radius: radius,
          backgroundColor: avatarColor,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  _initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: radius * 0.58,
                  ),
                )
              : null,
        ),
      );
    }

    return avatar;
  }
}

import 'package:admin/core/constants/color_constants.dart';
import 'package:flutter/material.dart';

/// Reusable ambient background layer.
///
/// Uses a warm, soft-glow pink, rose, and peach palette with a central
/// radial aura layer to recreate the ambient lighting effect from the design.
class DashboardBackground extends StatelessWidget {
  final Widget child;

  const DashboardBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }
}

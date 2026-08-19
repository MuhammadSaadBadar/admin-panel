import 'package:flutter/material.dart';

/// Reusable background layer for the Appointment feature screens.
///
/// Renders the registered `assets/images/appointment_bg.png` as a full-bleed
/// background with `BoxFit.cover` so it scales responsively and preserves its
/// aspect ratio without distortion. An optional subtle white overlay is layered
/// on top to keep the existing cards/text readable while allowing the image to
/// show through.
class AppointmentBackground extends StatelessWidget {
  final Widget child;

  /// Opacity of the white overlay drawn over the image (0 = no overlay,
  /// 1 = fully opaque white). Kept low so the image remains visible.
  final double overlayOpacity;

  const AppointmentBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.20,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image — covers the whole available area.
        Image.asset(
          'assets/images/appointment_bg.png',
          fit: BoxFit.cover,
          // Graceful fallback so the app still renders if the asset is missing.
          errorBuilder: (context, error, stackTrace) {
            return const ColoredBox(color: Color(0xFFF8F7FB));
          },
        ),
        // Subtle overlay to keep foreground content readable.
        ColoredBox(color: Colors.white.withOpacity(overlayOpacity)),
        child,
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constants.dart';

/// A SafeArea-aware app bar that accounts for the status-bar / notch height.
///
/// [preferredSize] advertises [kToolbarHeight] (56 dp) for the content row.
/// On top of that, [build] wraps the content in a [SafeArea] (top only) so
/// the status-bar inset is automatically respected on notched devices.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackTap;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = false,
    this.onBackTap,
  });

  // ── Preferred height: content height only.
  // Flutter's Scaffold adds the status-bar height on top automatically
  // when the bar is placed inside an AppBar slot, but because we are
  // using this widget inside a plain Column (not Scaffold.appBar), we
  // must account for the status-bar ourselves via SafeArea below.
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final MediaQueryData mq = MediaQuery.of(context);

    // Keep the status bar icons light (white) to match the dark theme.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark, // iOS
      ),
    );

    return Container(
      // Total height = status-bar padding + toolbar row.
      height: mq.padding.top + kToolbarHeight,
      decoration: BoxDecoration(
        color: ColorConstants.appBarBackground,
        border: Border(
          bottom: BorderSide(
            color: ColorConstants.onSurfaceVariant.withOpacity(0.3),
          ),
        ),
      ),
      child: SafeArea(
        // Consume only the top inset (status bar / notch).
        // left / right / bottom are handled by the surrounding Scaffold.
        bottom: false,
        child: SizedBox(
          height: kToolbarHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      if (showBackButton)
                        IconButton(
                          onPressed: onBackTap ?? () => Get.back(),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: ColorConstants.primary,
                          ),
                        ),
                      Flexible(
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isMobile ? 18 : 20,
                            fontWeight: FontWeight.w600,
                            color: ColorConstants.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: actions ?? const [],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

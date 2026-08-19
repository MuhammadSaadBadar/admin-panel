import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/color_constants.dart';
import '../utils/password_validator.dart';

/// A reusable password-strength requirements checklist.
///
/// Renders each requirement from [PasswordValidator.requirements] as a chip
/// with a check/unchecked icon that updates in real time as the user types.
/// This mirrors the "change password" UX and is shared so every screen that
/// collects a password enforces the exact same rules without duplicating logic.
class PasswordRequirementsChecklist extends StatelessWidget {
  /// The current password value used to evaluate each requirement.
  final String password;

  const PasswordRequirementsChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final requirements = PasswordValidator.requirements(password);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: requirements.map((req) {
        return _RequirementChip(label: req.label, isMet: req.isMet);
      }).toList(),
    );
  }
}

class _RequirementChip extends StatelessWidget {
  final String label;
  final bool isMet;

  const _RequirementChip({required this.label, required this.isMet});

  @override
  Widget build(BuildContext context) {
    final metColor = ColorConstants.success;
    final unmetColor = ColorConstants.onSurfaceVariant.withOpacity(0.5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: isMet ? metColor.withOpacity(0.14) : Colors.transparent,
        border: Border.all(
          color: isMet
              ? metColor.withOpacity(0.4)
              : ColorConstants.borderWhite10,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isMet ? metColor : unmetColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isMet ? metColor : unmetColor,
            ),
          ),
        ],
      ),
    );
  }
}

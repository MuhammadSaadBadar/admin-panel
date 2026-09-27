// lib/features/profile/widgets/commission_tile.dart

import 'package:admin/core/constants/color_constants.dart';
import 'package:admin/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class CommissionTile extends GetView<ProfileController> {
  const CommissionTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstants.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.onPrimary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.percent_rounded,
                color: ColorConstants.onPrimary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Platform Commission',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Obx(() {
                  if (controller.isUpdatingCommission.value) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    );
                  }
                  if (controller.isEditingCommission.value) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: TextButton(
                            onPressed: controller.toggleCommissionEditing,
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ColorConstants.onPrimary.withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: ElevatedButton(
                            onPressed: controller.saveCommission,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: ColorConstants.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Save',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: ColorConstants.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return TextButton(
                    onPressed: controller.toggleCommissionEditing,
                    style: TextButton.styleFrom(
                      foregroundColor: ColorConstants.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: ColorConstants.onPrimary.withOpacity(0.3),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit,
                          color: ColorConstants.onPrimary,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Edit',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: ColorConstants.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: ColorConstants.onPrimary.withOpacity(0.2)),
          const SizedBox(height: 16),

          // Content
          Obx(() {
            final methods = controller.paymentMethods.value;
            final isLoading = controller.isLoadingPaymentMethods.value;

            if (isLoading) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ColorConstants.onPrimary.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }

            if (controller.paymentMethodsError.value != null) {
              return Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: ColorConstants.error,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load commission',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: ColorConstants.onPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: controller.loadPaymentMethods,
                    child: Text(
                      'Retry',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ColorConstants.onPrimary,
                      ),
                    ),
                  ),
                ],
              );
            }

            if (methods == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No commission data available',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: ColorConstants.onPrimary.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!controller.isEditingCommission.value) ...[
                  // Display mode
                  Row(
                    children: [
                      Text(
                        'Current Commission Rate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: ColorConstants.onPrimary.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          methods.commissionDisplay,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: ColorConstants.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (methods.updatedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Last updated: ${_formatDate(methods.updatedAt!)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: ColorConstants.onPrimary.withOpacity(0.5),
                      ),
                    ),
                  ],
                ] else ...[
                  // Edit mode - Using dark theme colors for better visibility
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter Commission Percentage',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: ColorConstants.onPrimary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                controller.commissionInputError.value.isNotEmpty
                                ? ColorConstants.error
                                : ColorConstants.onPrimary.withOpacity(0.3),
                            width: 1.5,
                          ),
                          // Using dark theme surface color for better contrast
                          color: ColorConstants.darkThemeSurfaceHigh,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller.commissionTextController,
                                onChanged: (value) {
                                  controller.commissionInput.value = value;
                                  if (controller
                                      .commissionInputError
                                      .value
                                      .isNotEmpty) {
                                    controller.validateCommissionInput();
                                  }
                                },
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  // Using dark theme text color for visibility
                                  color: ColorConstants.textMain,
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'e.g. 20.00',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    // Using dark theme muted text for hint
                                    color: ColorConstants.darkTextMuted,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  suffixText: '%',
                                  suffixStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    // Using dark theme text color for suffix
                                    color: ColorConstants.darkThemeOnSurface
                                        .withOpacity(0.8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (controller.commissionInputError.value.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            controller.commissionInputError.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: ColorConstants.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (controller.commissionUpdateError.value != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: ColorConstants.error,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.commissionUpdateError.value!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: ColorConstants.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (controller.commissionUpdateSuccess.value) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: ColorConstants.success,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Commission updated successfully!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: ColorConstants.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hours = date.hour > 12 ? date.hour - 12 : date.hour;
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${months[date.month - 1]} ${date.day}, ${date.year} at ${hours}:${date.minute.toString().padLeft(2, '0')} $amPm';
  }
}

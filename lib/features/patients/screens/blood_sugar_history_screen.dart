import 'package:admin/core/constants/color_constants.dart';
import 'package:admin/core/routes/app_router.dart';
import 'package:admin/core/themes/app_theme.dart';
import 'package:admin/features/patients/repositories/patient_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BloodSugarHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final int patientId = Get.arguments['patientId'];
    Get.put<BloodSugarHistoryController>(
      BloodSugarHistoryController(Get.find(), patientId),
      tag: patientId.toString(),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('Blood Sugar History'),
        backgroundColor: ColorConstants.primary,
        elevation: 0,
      ),
      body: Obx(() {
        final controller = Get.find<BloodSugarHistoryController>(
          tag: patientId.toString(),
        );
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error.value != null) {
          return Center(child: Text(controller.error.value!));
        }
        return ListView.builder(
          itemCount: controller.history.length,
          itemBuilder: (context, index) {
            final entry = controller.history[index];
            final value = entry['value_mg_dl']?.toString() ?? '0';
            final date = DateTime.tryParse(
              entry['recorded_at']?.toString() ?? '',
            );
            final contextLabel = _getReadingContextLabel(
              entry['reading_context'] as String?,
            );
            final double? bloodSugarValue = (entry['value_mg_dl'] as num?)
                ?.toDouble();
            final bool isAboveTarget = (bloodSugarValue ?? 0) > 100;

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: ColorConstants.surfaceContainerLow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isAboveTarget
                        ? Colors.orange.withOpacity(0.1)
                        : ColorConstants.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isAboveTarget
                        ? Icons.arrow_upward_rounded
                        : Icons.check_rounded,
                    size: 18,
                    color: isAboveTarget
                        ? Colors.orange
                        : ColorConstants.primary,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      value,
                      style: AppTheme.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isAboveTarget
                            ? Colors.orange
                            : ColorConstants.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'mg/dL',
                      style: AppTheme.bodySmall.copyWith(
                        color: ColorConstants.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  contextLabel,
                  style: AppTheme.bodySmall.copyWith(
                    color: ColorConstants.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
                trailing: Text(
                  _formatDate(date),
                  style: AppTheme.labelMedium.copyWith(
                    color: ColorConstants.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  String _getReadingContextLabel(String? context) {
    switch (context) {
      case 'fasting':
        return 'Fasting';
      case 'post_meal':
        return 'Post-meal';
      case 'random':
        return 'Random';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}

class BloodSugarHistoryController extends GetxController {
  final PatientRepository _repository;
  final int patientId;

  BloodSugarHistoryController(this._repository, this.patientId);

  final RxList<dynamic> history = <dynamic>[].obs;
  final RxBool isLoading = false.obs;
  final RxnString error = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    error.value = null;
    try {
      final result = await _repository.getBloodSugarHistory(patientId);
      history.assignAll(result);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}

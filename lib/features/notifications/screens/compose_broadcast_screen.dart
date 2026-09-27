import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/color_constants.dart';
import '../../../core/widgets/custom_appbar.dart';
import '../../../core/widgets/dashboard_background.dart';
import '../controllers/notification_controller.dart';
import '../models/broadcast_request.dart';

/// Compose & send a broadcast notification.
///
/// Integrates:
/// - `POST /api/v1/notifications/broadcast/` — admin only, async fan-out
///
/// The backend returns **202 Accepted** immediately (the actual delivery is
/// queued via Celery). We treat that as success and show the server's detail
/// message. The audience dropdown maps to `target_role`:
///   Everyone → omitted (both patients & doctors)
///   Patients → `"patient"`
///   Doctors  → `"doctor"`
///
/// Admins are never recipients of a broadcast.
class ComposeBroadcastScreen extends StatefulWidget {
  const ComposeBroadcastScreen({super.key});

  @override
  State<ComposeBroadcastScreen> createState() => _ComposeBroadcastScreenState();
}

class _ComposeBroadcastScreenState extends State<ComposeBroadcastScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  BroadcastTargetRole _targetRole = BroadcastTargetRole.everyone;
  bool _showPreview = true;
  bool _isSending = false;

  static const int _maxTitleChars = 200;
  static const int _maxBodyChars = 500;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorConstants.scaffoldBackground,
      body: DashboardBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopAppBar(isMobile),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPageHeader(isMobile),
                          SizedBox(height: isMobile ? 16 : 24),
                          _buildGridLayout(isMobile),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopAppBar(bool isMobile) {
    return CustomAppBar(
      title: 'New Broadcast',
      showBackButton: true,
      onBackTap: () => Navigator.pop(context),
    );
  }

  Widget _buildPageHeader(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compose Broadcast',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 20 : 28,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onSurface,
          ),
        ),
        SizedBox(height: isMobile ? 4 : 8),
        Text(
          'Send updates to patients and/or doctors. Delivery is asynchronous.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 12 : 14,
            color: ColorConstants.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildGridLayout(bool isMobile) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 7, child: _buildComposerPanel(isMobile)),
          const SizedBox(width: 24),
          Expanded(flex: 5, child: _buildPreviewPanel(isMobile)),
        ],
      );
    }
    return Column(
      children: [
        _buildComposerPanel(isMobile),
        SizedBox(height: isMobile ? 16 : 24),
        _buildPreviewPanel(isMobile),
      ],
    );
  }

  Widget _buildComposerPanel(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: ColorConstants.primary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAudienceDropdown(isMobile),
          const SizedBox(height: 20),
          _buildLabel(
            'NOTIFICATION TITLE',
            _titleController.text.length,
            _maxTitleChars,
            isMobile,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _titleController,
            hint: 'e.g., System maintenance update',
            maxLines: 1,
            maxLength: _maxTitleChars,
            isMobile: isMobile,
          ),
          const SizedBox(height: 20),
          _buildLabel(
            'MESSAGE BODY',
            _messageController.text.length,
            _maxBodyChars,
            isMobile,
          ),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _messageController,
            hint: 'Enter the broadcast message details here...',
            maxLines: 6,
            minLines: 4,
            maxLength: _maxBodyChars,
            isMobile: isMobile,
          ),
          const SizedBox(height: 20),
          _buildActionArea(isMobile),
        ],
      ),
    );
  }

  Widget _buildAudienceDropdown(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('TARGET AUDIENCE', null, null, isMobile),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: ColorConstants.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorConstants.borderWhite10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<BroadcastTargetRole>(
              value: _targetRole,
              isExpanded: true,
              icon: const Icon(
                Icons.expand_more,
                color: ColorConstants.onSurfaceVariant,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              style: GoogleFonts.plusJakartaSans(
                fontSize: isMobile ? 14 : 15,
                color: ColorConstants.onSurface,
              ),
              dropdownColor: ColorConstants.surfaceContainer,
              items: const [
                DropdownMenuItem(
                  value: BroadcastTargetRole.everyone,
                  child: Text('Everyone (Patients & Doctors)'),
                ),
                DropdownMenuItem(
                  value: BroadcastTargetRole.patients,
                  child: Text('All Patients Only'),
                ),
                DropdownMenuItem(
                  value: BroadcastTargetRole.doctors,
                  child: Text('All Doctors Only'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _targetRole = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(
    String label,
    int? currentCount,
    int? maxCount,
    bool isMobile,
  ) {
    final over =
        currentCount != null && maxCount != null && currentCount > maxCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isMobile ? 11 : 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: ColorConstants.onPrimary,
          ),
        ),
        if (currentCount != null && maxCount != null)
          Text(
            '$currentCount / $maxCount',
            style: GoogleFonts.plusJakartaSans(
              fontSize: isMobile ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: over
                  ? ColorConstants.error
                  : ColorConstants.onPrimary.withOpacity(0.7),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    int? minLines,
    required int maxLength,
    required bool isMobile,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: (value) => setState(() {}),
      style: GoogleFonts.plusJakartaSans(
        fontSize: isMobile ? 14 : 15,
        color: ColorConstants.onSurface,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: isMobile ? 14 : 15,
          color: ColorConstants.onSurfaceVariant.withOpacity(0.5),
        ),
        filled: true,
        fillColor: ColorConstants.surfaceContainerLow,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstants.borderWhite10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstants.borderWhite10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstants.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildActionArea(bool isMobile) {
    final bool canSend =
        _titleController.text.trim().isNotEmpty &&
        _messageController.text.trim().isNotEmpty &&
        _titleController.text.trim().length <= _maxTitleChars &&
        _messageController.text.trim().length <= _maxBodyChars;

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: ColorConstants.borderWhite5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => setState(() => _showPreview = !_showPreview),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: ColorConstants.onPrimary,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  _showPreview ? 'Hide preview' : 'Show preview',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isMobile ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: ColorConstants.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: canSend && !_isSending ? _confirmSend : null,
              icon: _isSending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ColorConstants.primary,
                      ),
                    )
                  : const Icon(
                      Icons.send,
                      size: 18,
                    ),
              label: Text(
                _isSending ? 'Sending...' : 'Send Broadcast',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // Changed to white
                foregroundColor:
                    ColorConstants.primary, // Text/icon color on white
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2, // Optional: add slight elevation for depth
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(bool isMobile) {
    if (!_showPreview) {
      return const SizedBox.shrink();
    }

    final title = _titleController.text.trim().isEmpty
        ? 'Broadcast title'
        : _titleController.text.trim();
    final body = _messageController.text.trim().isEmpty
        ? 'Enter the broadcast message to see how it appears on devices...'
        : _messageController.text.trim();

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: ColorConstants.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.borderWhite10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.smartphone,
                color: ColorConstants.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Live Preview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.w600,
                  color: ColorConstants.onSurface,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorConstants.notifPinkSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Push Notification',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: ColorConstants.notifPink,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Notification card preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.surfaceContainerHigh.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorConstants.borderWhite10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ColorConstants.notifPinkSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.campaign,
                    color: ColorConstants.notifPink,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mama Health',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.onSurface.withOpacity(0.7),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: ColorConstants.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Audience: ${_audienceLabel(_targetRole)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Preview is approximate. Appearance may vary by device OS.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: ColorConstants.onSurfaceVariant.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  String _audienceLabel(BroadcastTargetRole role) {
    switch (role) {
      case BroadcastTargetRole.everyone:
        return 'Everyone (Patients & Doctors)';
      case BroadcastTargetRole.patients:
        return 'All Patients Only';
      case BroadcastTargetRole.doctors:
        return 'All Doctors Only';
    }
  }

  void _confirmSend() {
    final controller = Get.find<NotificationController>();

    Get.dialog(
      AlertDialog(
        backgroundColor: ColorConstants.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Send Broadcast?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: ColorConstants.onPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to send a broadcast to:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: ColorConstants.onPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audience: ${_audienceLabel(_targetRole)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorConstants.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Title: ${_titleController.text.trim()}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: ColorConstants.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ColorConstants.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _send(controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryContainer,
              foregroundColor: ColorConstants.onPrimaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Send Now',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _send(NotificationController controller) async {
    setState(() => _isSending = true);

    final request = BroadcastRequest(
      title: _titleController.text.trim(),
      body: _messageController.text.trim(),
      targetRole: _targetRole,
    );

    final success = await controller.broadcast(request);

    if (!mounted) return;
    setState(() => _isSending = false);

    if (success) {
      // Clear the form and return to the inbox.
      _titleController.clear();
      _messageController.clear();
      Get.back();
    }
  }
}

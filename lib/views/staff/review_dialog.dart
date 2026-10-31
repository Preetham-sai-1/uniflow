import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../widgets/status_badge.dart';

class ReviewDecisionDialog extends StatefulWidget {
  final JourneyRequest request;
  final AppState appState;
  final bool isAdmin;

  const ReviewDecisionDialog({
    super.key,
    required this.request,
    required this.appState,
    this.isAdmin = false,
  });

  @override
  State<ReviewDecisionDialog> createState() => _ReviewDecisionDialogState();
}

class _ReviewDecisionDialogState extends State<ReviewDecisionDialog> {
  final _commentController = TextEditingController();
  bool _isRejectMode = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleDecision(bool approve) {
    final comment = _commentController.text.trim();

    if (!approve && comment.isEmpty) {
      setState(() {
        _errorMessage =
            'A mandatory comment / reason is required for rejection.';
        _isRejectMode = true;
      });
      return;
    }

    if (widget.isAdmin) {
      widget.appState.adminReviewRequest(
        requestId: widget.request.id,
        approve: approve,
        comment: comment,
      );
    } else {
      widget.appState.staffReviewRequest(
        requestId: widget.request.id,
        approve: approve,
        comment: comment,
      );
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            approve ? AppColors.statusApproved : AppColors.statusRejected,
        content: Text(
          approve
              ? 'Request ${widget.request.id} approved successfully!'
              : 'Request ${widget.request.id} rejected with recorded note.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.rate_review_rounded,
                      color: AppColors.primaryBlue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isAdmin
                              ? 'Executive Administrative Review'
                              : 'Staff Department Review',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.request.serviceType.title} • ${widget.request.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusBadge(
                            status: widget.request.status, isCompact: true),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 28),

              // Student Overview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: [
                    _infoRow('Student Name', widget.request.studentName),
                    const SizedBox(height: 8),
                    _infoRow('Roll / ID', widget.request.studentRoll),
                    const SizedBox(height: 8),
                    _infoRow('Department', widget.request.department),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              const Text(
                'Submitted Request Information',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),

              // Submitted Data
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Column(
                  children: widget.request.formData.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _infoRow(e.key, e.value),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 20),

              // Reviewer Comment Field
              Text(
                _isRejectMode
                    ? 'Mandatory Rejection Reason *'
                    : 'Reviewer Remarks / Audit Note',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _isRejectMode
                      ? AppColors.statusRejected
                      : AppColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _isRejectMode
                      ? 'State why this request cannot be approved (e.g. invalid document, unpaid fee, slot occupied)...'
                      : 'Optional endorsement note for student records...',
                  errorText: _errorMessage,
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

              const SizedBox(height: 24),

              // Action Buttons
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 360;
                  final rejectButton = OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusRejected,
                      side: const BorderSide(color: AppColors.statusRejected),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Reject Request'),
                    onPressed: () => _handleDecision(false),
                  );

                  final approveButton = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusApproved,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                        widget.isAdmin ? 'Approve & Issue' : 'Approve Step'),
                    onPressed: () => _handleDecision(true),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        approveButton,
                        const SizedBox(height: 10),
                        rejectButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: rejectButton),
                      const SizedBox(width: 14),
                      Expanded(child: approveButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 115,
          child: Text(
            label,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/api/api_exceptions.dart';
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
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleDecision(bool approve) async {
    final comment = _commentController.text.trim();

    if (!approve && comment.isEmpty) {
      setState(() {
        _errorMessage =
            'A mandatory comment / reason is required for rejection.';
        _isRejectMode = true;
      });
      return;
    }

    if (_isSubmitting) return;

    if (!widget.appState.isAuthenticated) {
      // Local fallback for offline/unauthenticated tests
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
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final targetId = widget.request.backendId ?? widget.request.id;
      final stepIdx = widget.request.currentStepIndex;

      JourneyRequest updated;
      if (approve) {
        updated = await widget.appState.submitStepApproval(
          requestId: targetId,
          stepIndex: stepIdx,
          comment: comment,
        );
      } else {
        updated = await widget.appState.submitStepRejection(
          requestId: targetId,
          stepIndex: stepIdx,
          comment: comment,
        );
      }

      if (mounted) {
        Navigator.pop(context, updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                approve ? AppColors.statusApproved : AppColors.statusRejected,
            content: Text(
              approve
                  ? 'Request ${widget.request.effectiveId} approved successfully!'
                  : 'Request ${widget.request.effectiveId} rejected with recorded note.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Action failed: ${e.toString()}';
        });
      }
    }
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
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.statusRejectedBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.statusRejected.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          size: 16, color: AppColors.statusRejected),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.statusRejected,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

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
                    icon: _isSubmitting && _isRejectMode
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.statusRejected,
                            ),
                          )
                        : const Icon(Icons.close_rounded, size: 18),
                    label: Text(_isSubmitting && _isRejectMode
                        ? 'Rejecting...'
                        : 'Reject Request'),
                    onPressed:
                        _isSubmitting ? null : () => _handleDecision(false),
                  );

                  final approveButton = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusApproved,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _isSubmitting && !_isRejectMode
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: Text(_isSubmitting && !_isRejectMode
                        ? 'Approving...'
                        : (widget.isAdmin
                            ? 'Approve & Issue'
                            : 'Approve Step')),
                    onPressed:
                        _isSubmitting ? null : () => _handleDecision(true),
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

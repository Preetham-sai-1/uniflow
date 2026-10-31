import 'package:flutter/material.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/state/app_state.dart';
import '../../models/journey_request.dart';
import '../../widgets/journey_timeline.dart';
import '../../widgets/responsive_container.dart';
import '../../widgets/status_badge.dart';

class RequestDetailView extends StatefulWidget {
  final String requestId;
  final JourneyRequest? initialRequest;
  final AppState appState;

  const RequestDetailView({
    super.key,
    required this.requestId,
    this.initialRequest,
    required this.appState,
  });

  @override
  State<RequestDetailView> createState() => _RequestDetailViewState();
}

class _RequestDetailViewState extends State<RequestDetailView> {
  JourneyRequest? _request;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPaying = false;

  @override
  void initState() {
    super.initState();
    _request =
        widget.initialRequest ?? widget.appState.findRequest(widget.requestId);
    _isLoading = _request == null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDetails();
    });
  }

  Future<void> _fetchDetails() async {
    if (_request != null && !widget.appState.isAuthenticated) {
      return;
    }

    if (_request == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final targetId = _request?.backendId ?? _request?.id ?? widget.requestId;
      final details = await widget.appState.loadRequestDetails(targetId);
      if (mounted) {
        setState(() {
          _request = details;
          _errorMessage = null;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          if (e.statusCode == 404) {
            _errorMessage = 'Request not found (404).';
          } else if (e.statusCode == 403) {
            _errorMessage =
                'You do not have permission to view this request (403).';
          } else if (e.statusCode == 401) {
            _errorMessage =
                'Session expired or unauthorized. Please log in again.';
          } else {
            _errorMessage = e.message;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _request != null
              ? null
              : 'Failed to load request: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePayment() async {
    if (_isPaying || _request == null) return;

    setState(() {
      _isPaying = true;
    });

    try {
      final targetId = _request!.backendId ?? _request!.id;
      final updated = await widget.appState.submitStudentPayment(targetId);

      if (mounted) {
        setState(() {
          _request = updated;
          _isPaying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.statusApproved,
            content: Text(
              'Fee payment confirmed! Request forwarded to Administrative Approval.',
            ),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusRejected,
            content: Text(e.message),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.statusRejected,
            content: Text('Payment failed: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_request == null) {
      if (_errorMessage != null) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.requestId)),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 56, color: AppColors.statusRejected),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Retry'),
                        onPressed: _fetchDetails,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }

      return Scaffold(
        appBar: AppBar(title: Text(widget.requestId)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading journey details...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final request = _request!;

    return Scaffold(
      appBar: AppBar(
        title: Text(request.requestNumber.isNotEmpty
            ? request.requestNumber
            : request.id),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: StatusBadge(status: request.status, isCompact: true),
            ),
          ),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh details',
              onPressed: _fetchDetails,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ResponsiveContainer(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            maxWidth: 840,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Service Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          request.serviceType.icon,
                          size: 28,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.effectiveServiceName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Submitted on ${_formatDate(request.submittedAt)} • ${request.department.isNotEmpty ? request.department : "General Records"}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Simulated Payment Callout (if Payment Required)
                if (request.status == JourneyStatus.paymentRequired) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC4B5FD)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payment_rounded,
                                color: AppColors.statusPayment, size: 24),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Action Required: Processing Fee',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusPayment,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Security verification passed. Please complete the simulated replacement fee payment (₹${request.feeAmount > 0 ? request.feeAmount.toStringAsFixed(0) : "200"}) to advance to administrative sign-off.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4C1D95),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Notice: This is a simulated campus payment demonstration. No actual financial charge occurs.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B21A8),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusPayment,
                              foregroundColor: Colors.white,
                            ),
                            icon: _isPaying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.check_circle_outline_rounded,
                                    size: 18),
                            label: Text(_isPaying
                                ? 'Processing Payment...'
                                : 'Pay ₹${request.feeAmount > 0 ? request.feeAmount.toStringAsFixed(0) : "200"} Now (Simulated)'),
                            onPressed: _isPaying ? null : _handlePayment,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejection Alert Banner (if Rejected)
                if (request.status == JourneyStatus.rejected) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.statusRejected.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.statusRejected, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Request Terminated (Rejected)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusRejected,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                request.rejectionReason ??
                                    'This request was rejected during institutional review. See timeline details below.',
                                style: const TextStyle(
                                  color: AppColors.statusRejected,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Completion Celebration Banner
                if (request.status == JourneyStatus.approved) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.statusApprovedBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.statusApproved.withOpacity(0.3)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.statusApproved, size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Journey Successfully Completed',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.statusApproved,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'All verification steps have been approved by institutional authorities. The requested service is finalized.',
                                style: TextStyle(
                                  color: AppColors.statusApproved,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Live Journey Stepper Timeline
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Journey Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Live audit trail showing reviewers, timestamps, and verification milestones.',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const Divider(height: 28),
                      JourneyTimelineWidget(steps: request.timeline),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Request Submission Details / Form Fields
                if (request.formData.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Application Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Information submitted with this service request.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const Divider(height: 28),
                        ...request.formData.entries.map((entry) {
                          final isMobile =
                              MediaQuery.of(context).size.width < 600;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: isMobile
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        entry.value,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: AppColors.primaryNavy,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: 180,
                                        child: Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: AppColors.primaryNavy,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          );
                        }),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

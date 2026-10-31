import 'package:flutter/material.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/student_workflow_service.dart';
import '../../core/state/app_state.dart';
import '../../models/service_item.dart';
import '../../widgets/responsive_container.dart';

class RequestFormView extends StatefulWidget {
  final ServiceType serviceType;
  final CampusServiceItem? service;
  final AppState appState;

  const RequestFormView({
    super.key,
    required this.serviceType,
    this.service,
    required this.appState,
  });

  @override
  State<RequestFormView> createState() => _RequestFormViewState();
}

class _RequestFormViewState extends State<RequestFormView> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _errorMessage;

  // Bonafide fields
  String _bonafidePurpose = 'Educational Loan Application';
  String _academicSemester = '6th Semester (Spring 2026)';
  int _copies = 1;
  bool _urgent = false;
  final _remarksController = TextEditingController();

  // ID Card fields
  String _idReason = 'Lost on campus';
  final _firController = TextEditingController();
  final _phoneController = TextEditingController(text: '+1 (555) 019-2834');
  String _pickupLocation = 'Student Affairs Office (Counter 3)';

  // Equipment fields
  String _equipmentCategory = 'Audio/Visual 4K Projector';
  String _timeSlot = '09:00 AM - 01:00 PM (Morning Slot)';
  DateTime _bookingDate = DateTime.now().add(const Duration(days: 1));
  final _supervisorController =
      TextEditingController(text: 'Prof. Henderson (CSE Dept)');
  final _purposeController = TextEditingController();

  @override
  void dispose() {
    _remarksController.dispose();
    _firController.dispose();
    _phoneController.dispose();
    _supervisorController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  String _defaultSlugForType(ServiceType type) {
    switch (type) {
      case ServiceType.bonafide:
        return 'bonafide-certificate';
      case ServiceType.idCard:
        return 'id-card-replacement';
      case ServiceType.equipment:
        return 'equipment-booking';
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;

    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final Map<String, dynamic> formData = {};

    switch (widget.serviceType) {
      case ServiceType.bonafide:
        formData['purpose'] = _bonafidePurpose;
        formData['copies'] = _copies;
        formData['academicSemester'] = _academicSemester;
        formData['urgentProcessing'] =
            _urgent ? 'Yes (Within 48h)' : 'Standard (3-5 Days)';
        if (_remarksController.text.trim().isNotEmpty) {
          formData['additionalDetails'] = _remarksController.text.trim();
        }
        break;

      case ServiceType.idCard:
        String reason = 'Lost';
        final lower = _idReason.toLowerCase();
        if (lower.contains('stolen') || lower.contains('robbed')) {
          reason = 'Stolen';
        } else if (lower.contains('broken') ||
            lower.contains('chipped') ||
            lower.contains('error')) {
          reason = 'Damaged';
        }

        if (reason == 'Stolen' && _firController.text.trim().isEmpty) {
          setState(() {
            _errorMessage =
                'Police Complaint / FIR reference is required when reporting a stolen card.';
          });
          return;
        }

        formData['reason'] = reason;
        formData['contactNumber'] = _phoneController.text.trim();
        formData['pickupLocation'] = _pickupLocation;
        formData['originalReason'] = _idReason;
        if (_firController.text.trim().isNotEmpty) {
          formData['policeComplaintRef'] = _firController.text.trim();
        }
        break;

      case ServiceType.equipment:
        int startHour = 9;
        int endHour = 13;
        if (_timeSlot.contains('Afternoon')) {
          startHour = 14;
          endHour = 18;
        } else if (_timeSlot.contains('Full Day')) {
          startHour = 9;
          endHour = 17;
        }

        final startDateTime = DateTime(
          _bookingDate.year,
          _bookingDate.month,
          _bookingDate.day,
          startHour,
          0,
        );
        final endDateTime = DateTime(
          _bookingDate.year,
          _bookingDate.month,
          _bookingDate.day,
          endHour,
          0,
        );

        formData['equipmentName'] = _equipmentCategory;
        formData['purpose'] = _purposeController.text.trim();
        formData['startTime'] = startDateTime.toIso8601String();
        formData['endTime'] = endDateTime.toIso8601String();
        formData['timeSlot'] = _timeSlot;
        formData['supervisor'] = _supervisorController.text.trim();
        break;
    }

    final serviceIdentifier = widget.service?.id ??
        widget.service?.slug ??
        _defaultSlugForType(widget.serviceType);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final result = await widget.appState.submitStudentRequest(
        serviceId: serviceIdentifier,
        formData: formData,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => _SuccessConfirmationDialog(
          result: result,
          serviceTitle: widget.service?.title ?? widget.serviceType.title,
          onClose: () {
            Navigator.of(dialogCtx).pop();
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusRejected,
          content: Text(e.message),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Submission failed: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.statusRejected,
          content: Text(_errorMessage!),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.service?.title ?? widget.serviceType.title;
    final sla = widget.service?.sla ?? widget.serviceType.standardSla;

    return Scaffold(
      appBar: AppBar(
        title: Text('New $title Request'),
      ),
      body: ResponsiveContainer(
        maxWidth: 720,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.service?.icon ?? widget.serviceType.icon,
                        color: AppColors.primaryBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Standard SLA: $sla • Verified by Institutional Staff',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Dynamic Form Body
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
                      'Request Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Fill in the specific details required for verification.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 28),

                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.statusRejectedBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.statusRejected.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.statusRejected, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.statusRejected,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    if (widget.serviceType == ServiceType.bonafide)
                      _buildBonafideFields()
                    else if (widget.serviceType == ServiceType.idCard)
                      _buildIdCardFields()
                    else
                      _buildEquipmentFields(),

                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_isSubmitting
                            ? 'Submitting Request...'
                            : 'Submit Request to Campus Office'),
                        onPressed: _isSubmitting ? null : _submitForm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBonafideFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Purpose of Certificate *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _bonafidePurpose,
          items: [
            'Educational Loan Application',
            'Passport / Visa Verification',
            'Scholarship Proof of Enrolment',
            'Internship / Company Verification',
            'Personal Bank Account Opening',
            'Other Academic Purpose',
          ]
              .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) => setState(() => _bonafidePurpose = val!),
        ),
        const SizedBox(height: 20),
        const Text('Current Academic Semester *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _academicSemester,
          items: [
            '1st Semester (Freshman)',
            '2nd Semester',
            '3rd Semester (Sophomore)',
            '4th Semester',
            '5th Semester (Junior)',
            '6th Semester (Spring 2026)',
            '7th Semester (Senior)',
            '8th Semester',
          ]
              .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) => setState(() => _academicSemester = val!),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Number of Physical Copies',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    value: _copies,
                    items: [1, 2, 3, 5]
                        .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('$c ${c == 1 ? "Copy" : "Copies"}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (val) => setState(() => _copies = val!),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Priority / Urgent Processing',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: const Text(
              'Select if needed for immediate university or embassy deadline (within 48 hrs)',
              style: TextStyle(fontSize: 12)),
          value: _urgent,
          onChanged: (val) => setState(() => _urgent = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 16),
        const Text('Additional Remarks / Address Details (Optional)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _remarksController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Include specific wording, recipient authority, or postal address if required...',
          ),
        ),
      ],
    );
  }

  Widget _buildIdCardFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Reason for Replacement *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _idReason,
          items: [
            'Lost on campus',
            'Lost outside campus grounds',
            'Card physically broken or chipped',
            'Barcode / RFID chip reading error',
            'Stolen / Robbed (requires police note)',
            'Name or Department correction',
          ]
              .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) => setState(() => _idReason = val!),
        ),
        const SizedBox(height: 20),
        const Text('Police Reference / Incident Report ID',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _firController,
          decoration: const InputDecoration(
            hintText: 'Optional unless reported stolen (e.g. SEC-LOG-2026-91)',
          ),
        ),
        const SizedBox(height: 20),
        const Text('Contact Phone for Notification *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.phone_outlined, size: 20),
            hintText: '+1 (555) 000-0000',
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Phone number is required' : null,
        ),
        const SizedBox(height: 20),
        const Text('Preferred Card Collection Point *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _pickupLocation,
          items: [
            'Student Affairs Office (Counter 3)',
            'Main Security Gate Desk',
            'Department Secretary Desk',
          ]
              .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) => setState(() => _pickupLocation = val!),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEDE9FE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD6FE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.payment_rounded,
                  color: AppColors.statusPayment, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Notice: Replacement smart-cards carry a standard ₹200 printing fee payable online once approved by Security.',
                  style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4C1D95),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Equipment Category *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _equipmentCategory,
          items: [
            'Audio/Visual 4K Projector',
            'DSLR Photography & Cinema Video Kit',
            'IoT & Robotics Sensor Development Kit',
            'Mixed Reality / VR Oculus Headset',
            'Portable PA Sound System & Mic Kit',
          ]
              .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) => setState(() => _equipmentCategory = val!),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Date *',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _bookingDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setState(() => _bookingDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderSubtle),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.primaryBlue),
                          const SizedBox(width: 10),
                          Text(
                            '${_bookingDate.year}-${_bookingDate.month.toString().padLeft(2, '0')}-${_bookingDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Designated Time Slot *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: _timeSlot,
          items: [
            '09:00 AM - 01:00 PM (Morning Slot)',
            '02:00 PM - 06:00 PM (Afternoon Slot)',
            'Full Day (09:00 AM - 05:00 PM)',
          ]
              .map((val) => DropdownMenuItem(
                  value: val,
                  child: Text(val, overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (val) => setState(() => _timeSlot = val!),
        ),
        const SizedBox(height: 20),
        const Text('Faculty Sponsor / Supervisor *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _supervisorController,
          decoration: const InputDecoration(
            hintText: 'e.g. Prof. Henderson (CSE)',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Faculty sponsor is required'
              : null,
        ),
        const SizedBox(height: 20),
        const Text('Intended Purpose / Event Details *',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        TextFormField(
          controller: _purposeController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText:
                'Describe project requirements, lab venue, or presentation hall...',
          ),
          validator: (v) => v == null || v.trim().isEmpty
              ? 'Please describe intended use'
              : null,
        ),
      ],
    );
  }
}

class _SuccessConfirmationDialog extends StatelessWidget {
  final SubmissionResult result;
  final String serviceTitle;
  final VoidCallback onClose;

  const _SuccessConfirmationDialog({
    required this.result,
    required this.serviceTitle,
    required this.onClose,
  });

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'DEPARTMENT_VERIFICATION_PENDING':
        return 'Department Verification Pending';
      case 'SECURITY_REVIEW_PENDING':
        return 'Security Review Pending';
      case 'STAFF_REVIEW_PENDING':
        return 'Staff Review Pending';
      case 'FEE_PAYMENT_PENDING':
        return 'Payment Required';
      case 'ADMIN_APPROVAL_PENDING':
        return 'Admin Approval Pending';
      case 'SUBMITTED':
        return 'Submitted';
      case 'COMPLETED':
      case 'BOOKING_CONFIRMED':
        return 'Completed';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.statusApproved,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Application Submitted!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your request has been registered in the UniFlow campus engine and dispatched for departmental verification.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Tracking Number',
                    value: result.requestNumber,
                    isHighlight: true,
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    label: 'Service',
                    value: serviceTitle,
                  ),
                  const Divider(height: 16),
                  _InfoRow(
                    label: 'Initial Status',
                    value: _formatStatus(result.status),
                    statusColor: AppColors.primaryBlue,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onClose,
                child: const Text('Done & Return to Services'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final Color? statusColor;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w700,
              color: statusColor ??
                  (isHighlight ? AppColors.primaryBlue : AppColors.primaryNavy),
            ),
          ),
        ),
      ],
    );
  }
}

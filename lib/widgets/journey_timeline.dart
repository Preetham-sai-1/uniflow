import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/journey_request.dart';

class JourneyTimelineWidget extends StatelessWidget {
  final List<TimelineStep> steps;

  const JourneyTimelineWidget({
    super.key,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        Color iconColor;
        Color circleBg;
        IconData stepIcon;

        if (step.isRejected) {
          iconColor = AppColors.statusRejected;
          circleBg = AppColors.statusRejectedBg;
          stepIcon = Icons.cancel_rounded;
        } else if (step.isCompleted) {
          iconColor = AppColors.statusApproved;
          circleBg = AppColors.statusApprovedBg;
          stepIcon = Icons.check_circle_rounded;
        } else if (step.isCurrent) {
          iconColor = AppColors.primaryBlue;
          circleBg = const Color(0xFFEFF6FF);
          stepIcon = Icons.hourglass_top_rounded;
        } else {
          iconColor = AppColors.textMuted;
          circleBg = const Color(0xFFF1F5F9);
          stepIcon = Icons.radio_button_unchecked_rounded;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and vertical connector
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: circleBg,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            step.isCurrent ? AppColors.primaryBlue : circleBg,
                        width: step.isCurrent ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      stepIcon,
                      size: 20,
                      color: iconColor,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: step.isCompleted
                            ? AppColors.statusApproved.withOpacity(0.4)
                            : AppColors.borderSubtle,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: step.isCurrent
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: step.isRejected
                                    ? AppColors.statusRejected
                                    : AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              step.actorRole,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      if (step.comment != null && step.comment!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: step.isRejected
                                ? AppColors.statusRejectedBg
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: step.isRejected
                                  ? AppColors.statusRejected.withOpacity(0.3)
                                  : AppColors.borderSubtle,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                step.isRejected
                                    ? Icons.error_outline_rounded
                                    : Icons.chat_bubble_outline_rounded,
                                size: 14,
                                color: step.isRejected
                                    ? AppColors.statusRejected
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Note: ${step.comment!}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: step.isRejected
                                        ? AppColors.statusRejected
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

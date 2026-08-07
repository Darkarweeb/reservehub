import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';

class StepIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  const StepIndicatorWidget({
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: List.generate(totalSteps * 2 - 1, (i) {
            if (i.isOdd) {
              // Connector line
              final stepIndex = i ~/ 2;
              final isCompleted = stepIndex < currentStep;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 2,
                  color: isCompleted
                      ? AppTheme.secondary
                      : AppTheme.outlineLight,
                ),
              );
            } else {
              // Step circle
              final stepIndex = i ~/ 2;
              final isCompleted = stepIndex < currentStep;
              final isCurrent = stepIndex == currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.secondary
                      : isCurrent
                      ? AppTheme.primary
                      : AppTheme.backgroundLight,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? AppTheme.secondary
                        : isCurrent
                        ? AppTheme.primary
                        : AppTheme.outlineLight,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : Text(
                          '${stepIndex + 1}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isCurrent
                                ? Colors.white
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                ),
              );
            }
          }),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(totalSteps, (i) {
            final isActive = i <= currentStep;
            return Expanded(
              child: Text(
                stepLabels[i],
                textAlign: i == 0
                    ? TextAlign.left
                    : i == totalSteps - 1
                    ? TextAlign.right
                    : TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? AppTheme.primary : const Color(0xFF94A3B8),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

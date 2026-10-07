import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/prediction_result.dart';
import '../theme/app_theme.dart';

class ResultCard extends StatelessWidget {
  final PredictionResult result;

  const ResultCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final isSpam = result.isSpam;
    final primaryStatusColor = isSpam ? AppTheme.spamRed : AppTheme.hamGreen;
    final statusBgGlow = isSpam ? AppTheme.spamRedGlow : AppTheme.hamGreenGlow;

    final spamPercent = (result.spamProbability * 100).toStringAsFixed(1);
    final hamPercent = (result.hamProbability * 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: primaryStatusColor.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryStatusColor.withOpacity(0.18),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Badge Hero
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: statusBgGlow,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryStatusColor.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryStatusColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryStatusColor.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      isSpam
                          ? Icons.gpp_bad_rounded
                          : Icons.verified_user_rounded,
                      color: primaryStatusColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          result.isBlockedRule
                              ? '🚫 PRIVACY FILTERED SENDER'
                              : (isSpam ? 'SPAM DETECTED' : 'LEGITIMATE MESSAGE (HAM)'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: primaryStatusColor,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          result.isBlockedRule
                              ? (result.blockedRuleReason ?? 'Blocked matching internal privacy rule')
                              : (isSpam
                                  ? 'High risk of phishing, scam, or unverified link'
                                  : 'Verified standard text & conversation structure'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0),

            const SizedBox(height: 22),

            // Confidence Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Model Confidence',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textLight,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${isSpam ? spamPercent : hamPercent}% Score',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Spam Meter
            _buildProbabilityMeter(
              label: 'Spam Probability',
              percentageText: '$spamPercent%',
              value: result.spamProbability,
              activeColor: AppTheme.spamRed,
            ),
            const SizedBox(height: 14),

            // Ham Meter
            _buildProbabilityMeter(
              label: 'Legitimate (Ham) Probability',
              percentageText: '$hamPercent%',
              value: result.hamProbability,
              activeColor: AppTheme.hamGreen,
            ),

            // Keywords section if detected
            if (result.suspiciousKeywords.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Divider(color: AppTheme.borderDark, height: 1),
              const SizedBox(height: 16),
              Row(
                children: const [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.warningOrange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Flagged Suspicious Patterns:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warningOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: result.suspiciousKeywords.map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.warningOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.warningOrange.withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      '#$keyword',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.borderDark),
              ),
              child: Row(
                children: const [
                  Icon(Icons.bolt_rounded,
                      size: 18, color: AppTheme.accentCyan),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Evaluated 100% on-device using ONNX Runtime C++ engine (<1ms).',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProbabilityMeter({
    required String label,
    required String percentageText,
    required double value,
    required Color activeColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            Text(
              percentageText,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: activeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.02, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      activeColor.withOpacity(0.6),
                      activeColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}


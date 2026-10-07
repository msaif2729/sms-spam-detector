import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SampleSMS {
  final String title;
  final String content;
  final IconData icon;

  const SampleSMS({
    required this.title,
    required this.content,
    required this.icon,
  });
}

class SampleChips extends StatelessWidget {
  final Function(String) onSelectSample;

  const SampleChips({super.key, required this.onSelectSample});

  static const List<SampleSMS> samples = [
    SampleSMS(
      title: '🎁 Prize Scam',
      content: 'URGENT! You have won a 1,000 cash prize! Claim NOW at http://win-claim.com or call 080012345.',
      icon: Icons.card_giftcard_rounded,
    ),
    SampleSMS(
      title: '🔐 Phishing Alert',
      content: 'SECURITY WARNING: Your account access has been limited. Please click https://verify-bank.com to restore.',
      icon: Icons.lock_clock_rounded,
    ),
    SampleSMS(
      title: '💬 Regular Chat',
      content: 'Hey! Are we still meeting for lunch at 1 PM today? Let me know.',
      icon: Icons.chat_bubble_outline_rounded,
    ),
    SampleSMS(
      title: '📦 Delivery Track',
      content: 'Your package #84729 has been shipped and is out for delivery today via FedEx.',
      icon: Icons.local_shipping_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.primaryLight),
            SizedBox(width: 6),
            Text(
              'Try Sample SMS Templates',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: samples.map((sample) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  avatar: Icon(sample.icon, size: 16, color: AppTheme.primaryLight),
                  label: Text(
                    sample.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textLight,
                    ),
                  ),
                  backgroundColor: AppTheme.surfaceDark,
                  side: const BorderSide(color: AppTheme.borderDark, width: 1),
                  elevation: 2,
                  pressElevation: 4,
                  shadowColor: Colors.black.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  onPressed: () => onSelectSample(sample.content),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}


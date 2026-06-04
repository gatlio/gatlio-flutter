import 'package:flutter/material.dart';

class WarningBanner extends StatelessWidget {
  final VoidCallback onTriggerCardUpdate;
  final VoidCallback onDismiss;

  const WarningBanner({
    super.key,
    required this.onTriggerCardUpdate,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(bottom: BorderSide(color: Color(0x0FFFFFFF), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '!',
                style: TextStyle(
                  color: Color(0xFF111111),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Please update your payment method to avoid interruption.',
              style: TextStyle(fontSize: 13, color: Color(0xFFD4D4D4), height: 1.4),
              maxLines: 2,
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onTriggerCardUpdate,
            child: const Text(
              'Update now',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
          const SizedBox(width: 14),
          GestureDetector(
            onTap: onDismiss,
            child: const Text(
              '✕',
              style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ),
        ],
      ),
    );
  }
}

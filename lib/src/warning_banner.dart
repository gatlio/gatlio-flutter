import 'package:flutter/material.dart';

// No card-update CTA in warning state (#041): warning is only reachable via soft
// decline, where retrying — not re-entering card details — is the resolution path.
class WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const WarningBanner({
    super.key,
    required this.message,
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
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFFD4D4D4), height: 1.4),
              maxLines: 3,
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

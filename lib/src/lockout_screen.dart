import 'package:flutter/material.dart';
import 'entitlements.dart';

class LockoutScreen extends StatelessWidget {
  final bool poweredByWatermark;
  final VoidCallback onTriggerCardUpdate;

  const LockoutScreen({
    super.key,
    required this.poweredByWatermark,
    required this.onTriggerCardUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CardIcon(),
                  const SizedBox(height: 36),
                  const Text(
                    'Payment method declined',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your subscription is paused.\nUpdate your card to continue.',
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTriggerCardUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF111111),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        'Update payment method',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (poweredByWatermark)
            const Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Text(
                'Powered by Steadpay',
                style: TextStyle(fontSize: 12, color: Color(0xFF444444)),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _CardIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(height: 11, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 7),
              Container(
                width: 14,
                height: 10,
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '✕',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

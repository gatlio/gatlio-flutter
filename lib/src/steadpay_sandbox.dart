import 'package:flutter/material.dart';

import 'compute_transition.dart';
import 'lockout_screen.dart';
import 'steadpay_gate.dart';
import 'steadpay_status.dart';
import 'warning_banner.dart';

const String _kRecoveredNote =
    'onRecovered requires a real card update — test against a live Steadpay environment.';

const _kStatusColors = {
  SteadpayStatus.active: Color(0xFF22C55E),
  SteadpayStatus.warning: Color(0xFFF59E0B),
  SteadpayStatus.lockout: Color(0xFFEF4444),
  SteadpayStatus.error: Color(0xFF6B7280),
};

class SteadpaySandbox extends StatefulWidget {
  final VoidCallback? onLockout;
  final VoidCallback? onWarning;
  final VoidCallback? onActive;
  final void Function(Object)? onError;
  final LockoutScreenBuilder? lockoutScreen;
  final WarningBannerBuilder? warningBanner;
  final Widget child;

  const SteadpaySandbox({
    super.key,
    this.onLockout,
    this.onWarning,
    this.onActive,
    this.onError,
    this.lockoutScreen,
    this.warningBanner,
    required this.child,
  });

  @override
  State<SteadpaySandbox> createState() => _SteadpaySandboxState();
}

class _SteadpaySandboxState extends State<SteadpaySandbox> {
  SteadpayStatus _currentStatus = SteadpayStatus.active;
  SteadpayStatus? _lastStatus = SteadpayStatus.active;
  bool _panelOpen = false;
  bool _dismissed = false;
  final List<String> _log = [];

  void _changeStatus(SteadpayStatus next) {
    if (next == SteadpayStatus.error) {
      if (_currentStatus == SteadpayStatus.error) return;
      setState(() {
        _currentStatus = SteadpayStatus.error;
        _lastStatus = SteadpayStatus.error;
        _dismissed = false;
        _log.insert(0, 'onError(sandbox_error)');
        if (_log.length > 5) _log.removeLast();
      });
      widget.onError?.call(Exception('sandbox_error'));
      return;
    }

    final cbName = computeTransition(_lastStatus, next, false);
    setState(() {
      _currentStatus = next;
      _lastStatus = next;
      if (next != SteadpayStatus.warning) _dismissed = false;
      if (cbName != null) {
        _log.insert(0, '${cbName.name}()');
        if (_log.length > 5) _log.removeLast();
      }
    });

    if (cbName != null) {
      switch (cbName) {
        case CallbackName.onLockout:
          widget.onLockout?.call();
        case CallbackName.onWarning:
          widget.onWarning?.call();
        case CallbackName.onActive:
          widget.onActive?.call();
        case CallbackName.onRecovered:
          break;
      }
    }
  }

  Widget _buildGateContent() {
    if (_currentStatus == SteadpayStatus.lockout) {
      if (widget.lockoutScreen != null) {
        return widget.lockoutScreen!(
          triggerCardUpdate: () {},
          entitlements: null,
        );
      }
      return LockoutScreen(
        poweredByWatermark: true,
        onTriggerCardUpdate: () {},
      );
    }

    return Column(
      children: [
        if (_currentStatus == SteadpayStatus.warning && !_dismissed)
          widget.warningBanner != null
              ? widget.warningBanner!(
                  triggerCardUpdate: () {},
                  dismissWarning: () => setState(() => _dismissed = true),
                )
              : WarningBanner(
                  onTriggerCardUpdate: () {},
                  onDismiss: () => setState(() => _dismissed = true),
                ),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildDevBadge() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: GestureDetector(
            key: const Key('sandbox-dev-badge'),
            onTap: () => setState(() => _panelOpen = true),
            child: Container(
              width: 64,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text(
                'DEV',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSheetOverlay() {
    return [
      Positioned.fill(
        child: GestureDetector(
          onTap: () => setState(() => _panelOpen = false),
          child: Container(color: Colors.black54),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: const Color(0xFF0F0F0F),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          child: _buildSheetContent(),
        ),
      ),
    ];
  }

  Widget _buildSheetContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'STEADPAY SANDBOX',
                style: TextStyle(fontSize: 10, color: Color(0xFF444444), letterSpacing: 1),
              ),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _kStatusColors[_currentStatus] ?? Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _currentStatus.name,
              style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            SteadpayStatus.active,
            SteadpayStatus.warning,
            SteadpayStatus.lockout,
            SteadpayStatus.error,
          ].map((s) {
            final isActive = _currentStatus == s;
            return GestureDetector(
              key: Key('sandbox-pill-${s.name}'),
              onTap: () => _changeStatus(s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? (_kStatusColors[s] ?? Colors.grey) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  s.name,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? const Color(0xFF111111) : const Color(0xFF555555),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (_log.isNotEmpty) ...[
          const SizedBox(height: 12),
          ..._log.asMap().entries.map((e) => Text(
                '${e.key == 0 ? '▶' : ' '} ${e.value}',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'monospace',
                  color: e.key == 0 ? const Color(0xFF22C55E) : const Color(0xFF333333),
                ),
              )),
        ],
        const SizedBox(height: 12),
        const Text(
          _kRecoveredNote,
          key: Key('sandbox-recovered-note'),
          style: TextStyle(fontSize: 11, color: Color(0xFF666666), fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildGateContent(),
        _buildDevBadge(),
        if (_panelOpen) ..._buildSheetOverlay(),
      ],
    );
  }
}

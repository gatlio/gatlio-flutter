import 'package:flutter/material.dart';

const _metrics = [
  ('MRR', r'$12,840'),
  ('Active Users', '1,204'),
  ('Churn Rate', '2.4%'),
  ('Conversions', '8.7%'),
];

const _barRatios = [0.4, 0.6, 0.5, 0.8, 0.65, 0.9, 0.75];
const _maxBarHeight = 80.0;

const _events = [
  ('New subscriber', '2m ago'),
  ('Plan upgrade', '1h ago'),
  ('Trial started', '3h ago'),
];

class ArctaContent extends StatelessWidget {
  const ArctaContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricGrid(),
          const SizedBox(height: 20),
          _BarChart(),
          const SizedBox(height: 20),
          _RecentEvents(),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: _metrics.map((m) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(m.$2, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
            const SizedBox(height: 4),
            Text(m.$1, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      )).toList(),
    );
  }
}

class _BarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Revenue — last 7 days',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        SizedBox(
          height: _maxBarHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _barRatios.map((r) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: r * _maxBarHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _RecentEvents extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Events',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 8),
        ..._events.map((e) => Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(e.$1, style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
              Text(e.$2, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        )),
      ],
    );
  }
}

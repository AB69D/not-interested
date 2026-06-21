import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BatteryGuidanceScreen extends StatelessWidget {
  const BatteryGuidanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('Long-Run Setup', style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _InfoBanner(),
          const SizedBox(height: 20),
          _OemTile(
            brand: 'Samsung (One UI)',
            accentColor: const Color(0xFF1565C0),
            steps: const [
              'Settings → Battery and device care → Battery',
              'Background usage limits → Never sleeping apps → tap +',
              'Find "Not Interested" → OK',
              'Return to Battery → turn Off Adaptive battery',
            ],
          ),
          _OemTile(
            brand: 'Xiaomi / MIUI / HyperOS',
            accentColor: const Color(0xFFFF6900),
            steps: const [
              'Settings → Battery & performance → App battery saver',
              'Find "Not Interested" → No restrictions',
              'Settings → Manage apps → Not Interested → Autostart → Enable',
            ],
          ),
          _OemTile(
            brand: 'OnePlus (OxygenOS)',
            accentColor: const Color(0xFFE00B0B),
            steps: const [
              'Settings → Battery → Battery optimization',
              'Tap the dropdown → switch to "All apps"',
              'Find "Not Interested" → Don\'t optimize',
              'Settings → Battery → Advanced → turn Off Deep Optimization',
            ],
          ),
          _OemTile(
            brand: 'OPPO / Realme (ColorOS)',
            accentColor: const Color(0xFF00A86B),
            steps: const [
              'Settings → Additional settings → Battery → App battery optimization',
              'Find "Not Interested" → Don\'t optimize',
              'Open Security app → Startup Manager → Enable "Not Interested"',
            ],
          ),
          _OemTile(
            brand: 'Vivo (FunTouch OS)',
            accentColor: const Color(0xFF1890FF),
            steps: const [
              'Open i Manager app → App Manager → Autostart',
              'Enable "Not Interested"',
              'Settings → Battery → High Background Power Consumption',
              'Enable "Not Interested"',
            ],
          ),
          _OemTile(
            brand: 'Huawei (EMUI)',
            accentColor: const Color(0xFFCF0A2C),
            steps: const [
              'Settings → Battery → App launch',
              'Find "Not Interested" → turn Off "Manage automatically"',
              'Enable: Auto-launch, Secondary launch, Run in background',
            ],
          ),
          const SizedBox(height: 12),
          _GenericTile(),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1e2d4a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3b82f6).withValues(alpha: 0.4)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF60a5fa), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Some manufacturers aggressively kill background apps to save battery. '
              'Follow your phone brand\'s steps below to keep the content filter '
              'running for 30+ days without interruption.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _OemTile extends StatefulWidget {
  final String brand;
  final Color accentColor;
  final List<String> steps;

  const _OemTile({
    required this.brand,
    required this.accentColor,
    required this.steps,
  });

  @override
  State<_OemTile> createState() => _OemTileState();
}

class _OemTileState extends State<_OemTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1f2937)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.brand,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(color: Color(0xFF1f2937), height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (int i = 0; i < widget.steps.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1}.',
                            style: TextStyle(
                              color: widget.accentColor,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.steps[i],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GenericTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1f2937)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Any Android phone',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          SizedBox(height: 8),
          Text(
            'Settings → Apps → Not Interested → Battery → Unrestricted\n'
            '(Works on any Android 6+ device — do this first on any brand)',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

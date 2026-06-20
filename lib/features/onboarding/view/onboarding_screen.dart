import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(Icons.shield_outlined, 'Content Filter',
        'Blurs sensitive content on your screen — across every app — the moment it appears.'),
    _PageData(Icons.notifications_outlined, 'Stay Notified',
        'A small notification shows while protection is active. Tap Allow when Android asks.'),
    _PageData(Icons.layers_outlined, 'Draw Over Apps',
        'Required to display the blur effect. You will visit Settings just once to grant this.'),
    _PageData(Icons.screenshot_monitor_outlined, 'Screen Access',
        'When you tap Start, Android asks to share your screen. Choose "Start now" to continue.'),
  ];

  Future<void> _next() async {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
      if (mounted) context.go('/');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _PageView(data: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _page ? 20 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: i == _page
                                    ? const Color(0xFF3b82f6)
                                    : Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3b82f6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _page < _pages.length - 1 ? 'Continue →' : "Let's go!",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
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
}

class _PageData {
  final IconData icon;
  final String title;
  final String subtitle;
  const _PageData(this.icon, this.title, this.subtitle);
}

class _PageView extends StatelessWidget {
  final _PageData data;
  const _PageView({required this.data});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 80, color: const Color(0xFF3b82f6)),
          const SizedBox(height: 32),
          Text(data.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(data.subtitle,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 15, height: 1.6),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

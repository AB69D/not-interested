import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WhitelistScreen extends StatefulWidget {
  const WhitelistScreen({super.key});
  @override
  State<WhitelistScreen> createState() => _WhitelistScreenState();
}

class _WhitelistScreenState extends State<WhitelistScreen> {
  static const _ch = MethodChannel('com.yonderchat.not_interested/screen_capture');
  List<Map<String, String>> _apps = [];
  Set<String> _excluded = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('whitelisted_packages');
    final saved = raw != null ? (jsonDecode(raw) as List).cast<String>().toSet() : <String>{};
    try {
      final result = await _ch.invokeMethod<List>('getInstalledApps');
      final apps = (result ?? [])
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
      setState(() { _apps = apps; _excluded = saved; _loading = false; });
    } catch (_) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _toggle(String pkg, bool exclude) async {
    setState(() { exclude ? _excluded.add(pkg) : _excluded.remove(pkg); });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('whitelisted_packages', jsonEncode(_excluded.toList()));
    try { await _ch.invokeMethod('setWhitelistedApps', _excluded.toList()); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1117),
        title: const Text('App Exclusions', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Excluded apps will not be filtered',
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3b82f6)))
          : _apps.isEmpty
              ? const Center(child: Text('No apps found', style: TextStyle(color: Colors.white38)))
              : ListView.builder(
                  itemCount: _apps.length,
                  itemBuilder: (_, i) {
                    final app = _apps[i];
                    final pkg = app['packageName']!;
                    final excluded = _excluded.contains(pkg);
                    return ListTile(
                      title: Text(app['name']!, style: const TextStyle(color: Colors.white)),
                      subtitle: Text(pkg, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: Switch(
                        value: excluded,
                        onChanged: (v) => _toggle(pkg, v),
                        activeThumbColor: const Color(0xFF3b82f6),
                      ),
                    );
                  },
                ),
    );
  }
}

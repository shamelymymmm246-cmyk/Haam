import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:haam_counter/providers/security_state_provider.dart';
import 'package:haam_counter/screens/academy_screen.dart';
import 'package:haam_counter/screens/dashboard_screen.dart';
import 'package:haam_counter/screens/firewall_screen.dart';
import 'package:haam_counter/screens/network_screen.dart';
import 'package:haam_counter/screens/settings_screen.dart';
import 'package:haam_counter/screens/vault_screen.dart';
import 'package:haam_counter/widgets/ambient_background.dart';
import 'package:haam_counter/widgets/haam_bottom_nav.dart';
import 'package:haam_counter/widgets/haam_top_bar.dart';

/// الهيكل الرئيسي للتطبيق — 5 تبويبات بشريط تنقّل سفلي زجاجي،
/// مطابق لتصميم Haam في مجلد stitch.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // ابدأ فحصاً أمنياً حقيقياً عند فتح التطبيق (يغذّي Dashboard/Network/Firewall)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SecurityStateProvider>().refresh();
    });
  }

  void _go(int i) => setState(() => _index = i);

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(onSwitchTab: _go),
      const NetworkScreen(),
      const VaultScreen(),
      const FirewallScreen(),
      const AcademyScreen(),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: AmbientBackground(
        child: Column(
          children: [
            HaamTopBar(
              title: HaamBottomNav.items[_index].label,
              onNotifications: _openSettings,
              onProfile: _openSettings,
            ),
            Expanded(
              child: IndexedStack(index: _index, children: screens),
            ),
          ],
        ),
      ),
      bottomNavigationBar: HaamBottomNav(
        currentIndex: _index,
        onTap: _go,
      ),
    );
  }
}

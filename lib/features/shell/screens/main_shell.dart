import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

/// Bottom-navigation shell that wraps the 4 persistent tabs:
/// Home, Dialer, Contacts, Recents.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.home_outlined),
      activeIcon: Icon(Icons.home_rounded),
      label: 'Home',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.dialpad_outlined),
      activeIcon: Icon(Icons.dialpad_rounded),
      label: 'Dialer',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.contacts_outlined),
      activeIcon: Icon(Icons.contacts_rounded),
      label: 'Contacts',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.history_outlined),
      activeIcon: Icon(Icons.history_rounded),
      label: 'Recents',
    ),
  ];

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isOffline = false;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _checkConnectivity(),
    );
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 5));
      if (mounted) {
        setState(() => _isOffline = result.isEmpty || result[0].rawAddress.isEmpty);
      }
    } on SocketException {
      if (mounted) setState(() => _isOffline = true);
    } on TimeoutException {
      if (mounted) setState(() => _isOffline = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          if (_isOffline)
            MaterialBanner(
              backgroundColor: Colors.orange.shade800,
              content: const Text(
                'You are offline. Some features may not work.',
                style: TextStyle(color: Colors.white, fontSize: 13),
              ),
              leading:
                  const Icon(Icons.wifi_off, color: Colors.white, size: 20),
              actions: [
                TextButton(
                  onPressed: _checkConnectivity,
                  child: const Text('Retry',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: _NeuBottomNav(
        currentIndex: widget.navigationShell.currentIndex,
        items: MainShell._items,
        onTap: (index) => widget.navigationShell.goBranch(
          index,
          initialLocation: index == widget.navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// Custom neumorphic bottom navigation bar.
class _NeuBottomNav extends StatelessWidget {
  const _NeuBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg,
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowDark.withOpacity(0.25),
            offset: const Offset(0, -3),
            blurRadius: 12,
            spreadRadius: -2,
          ),
          BoxShadow(
            color: AppTheme.shadowLight.withOpacity(0.6),
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: selected
                              ? BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusFull),
                                )
                              : null,
                          child: IconTheme(
                            data: IconThemeData(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              size: 22,
                            ),
                            child: selected
                                ? items[i].activeIcon
                                : items[i].icon,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label ?? '',
                          style: TextStyle(
                            color: selected
                                ? AppTheme.primary
                                : AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

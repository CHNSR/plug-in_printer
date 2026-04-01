import 'package:flutter/material.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';
import 'screens/connection_screen.dart';
import 'screens/text_screen.dart';
import 'screens/hardware_screen.dart';
import 'screens/graphics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Printer Plugin Tester',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00838F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'sans-serif',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00838F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _plugin = FlutterPrinter01();
  bool _isConnected = false;

  void _updateConnectionStatus(bool status) {
    setState(() => _isConnected = status);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final modules = [
      ModuleItem(
        icon: Icons.lan_outlined,
        label: 'Connection',
        subtitle: 'IP, USB, Scan, Status',
        color: const Color(0xFF00838F),
        badge: _isConnected ? '🟢 Connected' : '🔴 Disconnected',
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => ConnectionScreen(
                plugin: _plugin,
                isConnected: _isConnected,
                onConnectionChanged: _updateConnectionStatus,
              ),
            ),
          );
          if (result != null) _updateConnectionStatus(result);
        },
      ),
      ModuleItem(
        icon: Icons.text_fields_outlined,
        label: 'Text',
        subtitle: 'พิมพ์ข้อความ / Print Text',
        color: const Color(0xFF5C6BC0),
        badge: _isConnected ? null : 'ต้องเชื่อมต่อก่อน',
        badgeWarning: !_isConnected,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TextScreen(plugin: _plugin, isConnected: _isConnected),
          ),
        ),
      ),
      ModuleItem(
        icon: Icons.hardware_outlined,
        label: 'Hardware',
        subtitle: 'Raw Bytes, ESC/POS Commands',
        color: const Color(0xFFF57C00),
        badge: _isConnected ? null : 'ต้องเชื่อมต่อก่อน',
        badgeWarning: !_isConnected,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                HardwareScreen(plugin: _plugin, isConnected: _isConnected),
          ),
        ),
      ),
      ModuleItem(
        icon: Icons.image_outlined,
        label: 'Graphics',
        subtitle: 'Widget, รูปภาพ, QR Code, Barcode',
        color: const Color(0xFF388E3C),
        badge: _isConnected ? null : 'ต้องเชื่อมต่อก่อน',
        badgeWarning: !_isConnected,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GraphicsScreen(plugin: _plugin, isConnected: _isConnected),
          ),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text(
              'Printer Plugin Tester',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: cs.surface,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 160,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 80, 20, 0),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? Colors.green.shade100
                            : cs.errorContainer.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _isConnected
                              ? Colors.green.shade300
                              : cs.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isConnected ? Icons.circle : Icons.circle_outlined,
                            size: 10,
                            color: _isConnected
                                ? Colors.green.shade600
                                : cs.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isConnected
                                ? 'Printer Connected'
                                : 'Not Connected',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isConnected
                                  ? Colors.green.shade800
                                  : cs.onErrorContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList.separated(
              itemCount: modules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => ModuleCard(item: modules[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class ModuleItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? badge;
  final bool badgeWarning;
  final VoidCallback onTap;

  ModuleItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.badge,
    this.badgeWarning = false,
    required this.onTap,
  });
}

class ModuleCard extends StatelessWidget {
  final ModuleItem item;
  const ModuleCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: item.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (item.badge != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: item.badgeWarning
                              ? cs.errorContainer.withOpacity(0.5)
                              : item.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.badge!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: item.badgeWarning
                                ? cs.onErrorContainer
                                : item.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
                size: 26,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

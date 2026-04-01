import 'package:flutter/material.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';

/// หน้าทดสอบ Network Scanner โดยเฉพาะ
class ScanNetworkScreen extends StatefulWidget {
  final FlutterPrinter01 plugin;
  const ScanNetworkScreen({super.key, required this.plugin});

  @override
  State<ScanNetworkScreen> createState() => _ScanNetworkScreenState();
}

class _ScanNetworkScreenState extends State<ScanNetworkScreen>
    with SingleTickerProviderStateMixin {
  final _portController = TextEditingController(text: '9100');
  final List<String> _foundPrinters = [];
  bool _isScanning = false;
  String _status = 'กด Scan เพื่อค้นหาเครื่องปริ้นเตอร์ในวงเน็ตเดียวกัน';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _startScan() async {
    final ports = _portController.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();

    if (ports.isEmpty) {
      setState(() => _status = 'กรุณากรอก Port ที่ถูกต้อง (เช่น 9100)');
      return;
    }

    setState(() {
      _isScanning = true;
      _foundPrinters.clear();
      _status = 'กำลังสแกน${ports.length > 1 ? " ${ports.length} พอร์ต" : " พอร์ต ${ports.first}"} กว่า 254 IPs...';
    });

    try {
      final result = await widget.plugin.connection.scanNetworkPrinters(ports: ports);
      if (!mounted) return;
      setState(() {
        _foundPrinters.addAll(result);
        _status = result.isEmpty
            ? 'ไม่พบเครื่องปริ้นเตอร์ ลองเช็ค IP/Port หรือวง LAN ดูครับ'
            : 'พบเครื่องปริ้นเตอร์ ${result.length} เครื่อง — แตะเพื่อเชื่อมต่อ';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Scan Error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _onPrinterSelected(String ip) {
    Navigator.of(context).pop(ip);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: const Text('Network Printer Scanner',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Status Card ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isScanning
                    ? cs.primaryContainer.withOpacity(0.6)
                    : _foundPrinters.isNotEmpty
                        ? Colors.green.shade50
                        : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isScanning
                      ? cs.primary
                      : _foundPrinters.isNotEmpty
                          ? Colors.green.shade300
                          : cs.outlineVariant,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  _isScanning
                      ? ScaleTransition(
                          scale: _pulseAnimation,
                          child: Icon(Icons.radar, color: cs.primary, size: 36),
                        )
                      : Icon(
                          _foundPrinters.isNotEmpty
                              ? Icons.print
                              : Icons.print_disabled_outlined,
                          color: _foundPrinters.isNotEmpty
                              ? Colors.green.shade600
                              : cs.onSurfaceVariant,
                          size: 36,
                        ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _status,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _isScanning
                            ? cs.primary
                            : _foundPrinters.isNotEmpty
                                ? Colors.green.shade800
                                : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Port Input ---
            TextField(
              controller: _portController,
              enabled: !_isScanning,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'พอร์ตที่จะสแกน (ใส่หลายพอร์ตคั่นด้วย ,)',
                hintText: '9100, 4000, 9101',
                prefixIcon: const Icon(Icons.settings_ethernet),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: cs.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 16),

            // --- Scan Button ---
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isScanning ? null : _startScan,
                icon: _isScanning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _isScanning ? 'กำลังสแกนวง LAN...' : 'เริ่มสแกน',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Results Header ---
            if (_foundPrinters.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'ผลลัพธ์ (${_foundPrinters.length} เครื่อง)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],

            // --- Results List ---
            Expanded(
              child: _foundPrinters.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_find_outlined,
                              size: 64, color: cs.outlineVariant),
                          const SizedBox(height: 12),
                          Text(
                            'ไม่พบเครื่องปริ้นเตอร์',
                            style: TextStyle(
                                color: cs.outlineVariant, fontSize: 15),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _foundPrinters.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ip = _foundPrinters[index];
                        return _PrinterListTile(
                          ip: ip,
                          port: int.tryParse(_portController.text.split(',').first.trim()) ?? 9100,
                          onTap: () => _onPrinterSelected(ip),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrinterListTile extends StatelessWidget {
  final String ip;
  final int port;
  final VoidCallback onTap;

  const _PrinterListTile({
    required this.ip,
    required this.port,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primaryContainer.withOpacity(0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.print, color: cs.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ip,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      'Port $port  •  แตะเพื่อเชื่อมต่อ',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

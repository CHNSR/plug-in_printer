import 'package:flutter/material.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';
import '../scan_network_screen.dart';
import 'shared_widgets.dart';

class ConnectionScreen extends StatefulWidget {
  final FlutterPrinter01 plugin;
  final bool isConnected;
  final ValueChanged<bool> onConnectionChanged;

  const ConnectionScreen({
    super.key,
    required this.plugin,
    required this.isConnected,
    required this.onConnectionChanged,
  });

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _ipController = TextEditingController(text: '192.168.2.106');
  final _portController = TextEditingController(text: '9100');
  bool _isConnected = false;
  bool _isLoading = false;
  String _status = 'Ready';

  @override
  void initState() {
    super.initState();
    _isConnected = widget.isConnected;
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    try {
      final port = int.tryParse(_portController.text) ?? 9100;
      final ok = await widget.plugin.connection.connectPrinter(_ipController.text, port);
      setState(() {
        _isConnected = ok;
        _status = ok ? '✅ เชื่อมต่อสำเร็จ' : '❌ เชื่อมต่อล้มเหลว';
      });
      widget.onConnectionChanged(ok);
    } catch (e) {
      setState(() { _status = 'Error: $e'; });
      widget.onConnectionChanged(false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.connection.disconnectPrinter();
      setState(() {
        _isConnected = !ok;
        _status = ok ? '🔌 ตัดการเชื่อมต่อแล้ว' : '❌ ตัดการเชื่อมต่อล้มเหลว';
      });
      widget.onConnectionChanged(!ok);
    } catch (e) {
      setState(() { _status = 'Error: $e'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkStatus() async {
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.connection.getConnectionStatus();
      setState(() {
        _isConnected = ok;
        _status = ok ? '🟢 Status: Connected' : '🔴 Status: Disconnected';
      });
      widget.onConnectionChanged(ok);
    } catch (e) {
      setState(() { _status = 'Error: $e'; });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _openScanScreen() async {
    final ip = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => ScanNetworkScreen(plugin: widget.plugin)),
    );
    if (ip != null && mounted) {
      setState(() {
        _ipController.text = ip;
        _status = '📡 พบ IP: $ip — กด Connect ได้เลย';
      });
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.inversePrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StatusCard(isConnected: _isConnected, status: _status),
          const SizedBox(height: 24),

          const SectionHeader(icon: Icons.wifi, label: 'Network (TCP/IP)'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: PrinterTextField(
                  controller: _ipController,
                  label: 'IP Address',
                  icon: Icons.router_outlined,
                  enabled: !_isConnected && !_isLoading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrinterTextField(
                  controller: _portController,
                  label: 'Port',
                  icon: Icons.electrical_services_outlined,
                  enabled: !_isConnected && !_isLoading,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ActionButton(
            label: 'Scan Network Printers',
            icon: Icons.radar,
            onTap: _isLoading ? null : _openScanScreen,
            outlined: true,
          ),
          const SizedBox(height: 8),
          ActionButton(
            label: _isConnected ? 'Disconnect' : 'Connect Printer',
            icon: _isConnected ? Icons.link_off : Icons.link,
            loading: _isLoading,
            onTap: _isLoading ? null : (_isConnected ? _disconnect : _connect),
            danger: _isConnected,
          ),

          const SizedBox(height: 24),
          const SectionHeader(icon: Icons.usb_outlined, label: 'USB'),
          const SizedBox(height: 12),
          ActionButton(
            label: 'Scan USB Devices',
            icon: Icons.search,
            outlined: true,
            onTap: _isLoading ? null : () async {
              setState(() => _isLoading = true);
              try {
                final devices = await widget.plugin.connection.getUsbDevices();
                if (!mounted) return;
                setState(() {
                  _status = devices.isEmpty
                      ? 'ไม่พบ USB Device'
                      : 'พบ: ${devices.map((d) => d['deviceName']).join(", ")}';
                });
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
          ),

          const SizedBox(height: 24),
          const SectionHeader(icon: Icons.monitor_heart_outlined, label: 'Status'),
          const SizedBox(height: 12),
          ActionButton(
            label: 'Check Connection Status',
            icon: Icons.sync_outlined,
            onTap: _isLoading ? null : _checkStatus,
            outlined: true,
          ),
        ],
      ),
    );
  }
}

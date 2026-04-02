import 'package:flutter/material.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';
import 'package:flutter_printer_01/src/modules/printer_hardware.dart';
import 'shared_widgets.dart';

class HardwareScreen extends StatefulWidget {
  final FlutterPrinter01 plugin;
  final bool isConnected;
  const HardwareScreen({
    super.key,
    required this.plugin,
    required this.isConnected,
  });

  @override
  State<HardwareScreen> createState() => _HardwareScreenState();
}

class _HardwareScreenState extends State<HardwareScreen> {
  final _rawBytesController = TextEditingController(text: '29, 86, 66, 0');
  bool _isLoading = false;
  String _status = '';
  bool _success = false;
  PrinterStatus? _printerStatus;

  Future<void> _checkPrinterStatus() async {
    setState(() => _isLoading = true);
    try {
      final status = await widget.plugin.hardware.getPrinterStatus();
      setState(() {
        _printerStatus = status;
        _success = status.isSuccess;
        _status = status.isSuccess
            ? 'สถานะ: ${status.state.name}\n${status.toString()}'
            : 'ดึงสถานะไม่สำเร็จ';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _status = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cutPaper() async {
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.hardware.cutPaper();
      setState(() {
        _success = ok;
        _status = ok
            ? '✅ ตัดกระดาษสำเร็จ (ESC/POS [29, 86, 66, 0])'
            : '❌ ตัดกระดาษล้มเหลว';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _status = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendCustomBytes() async {
    final parts = _rawBytesController.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toList();
    if (parts.isEmpty) {
      setState(() {
        _success = false;
        _status = 'กรุณากรอก Bytes ที่ถูกต้อง เช่น 27, 64';
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.hardware.sendRawBytes(parts);
      setState(() {
        _success = ok;
        _status = ok
            ? '✅ Raw Bytes [${parts.join(', ')}] ส่งสำเร็จ'
            : '❌ ส่งล้มเหลว';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _status = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _beep({int times = 2, int duration = 2}) async {
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.hardware.beep(
        times: times,
        duration: duration,
      );
      setState(() {
        _success = ok;
        _status = ok ? '✅ Beep ส่งสำเร็จ' : '❌ ส่งล้มเหลว';
      });
    } catch (e) {
      setState(() {
        _success = false;
        _status = 'Error: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _rawBytesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hardware Control',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cs.inversePrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!widget.isConnected) const NotConnectedBanner(),

          // ── Printer Status ──────────────────────────────────────────────────
          const SectionHeader(
            icon: Icons.info_outline,
            label: 'Printer Status',
          ),
          const SizedBox(height: 12),
          _EscPosRef(
            bytes: '16, 4, 1',
            description: 'DLE EOT 1 — Real-time Status',
          ),
          const SizedBox(height: 10),
          ActionButton(
            label: 'Check Status',
            icon: Icons.refresh,
            onTap: (widget.isConnected && !_isLoading)
                ? _checkPrinterStatus
                : null,
            loading: _isLoading,
            outlined: true,
          ),
          if (_printerStatus != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'State: ${_printerStatus!.state.name.toUpperCase()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Online: ${_printerStatus!.isOnline ? "✅" : "❌"} (Raw bit 3)',
                  ),
                  Text(
                    'Paper Feed Pushed: ${_printerStatus!.isPaperFeedButtonPressed ? "Yes" : "No"} (Raw bit 6)',
                  ),
                  Text(
                    'Drawer Kick-out: ${_printerStatus!.isDrawerKickOutHigh ? "High" : "Low"} (Raw bit 2)',
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Raw Byte: 0x${_printerStatus!.rawByte.toRadixString(16).padLeft(2, '0')}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 28),

          const SectionHeader(
            icon: Icons.content_cut_outlined,
            label: 'Cut Paper',
          ),
          const SizedBox(height: 12),
          _EscPosRef(bytes: '29, 86, 66, 0', description: 'GS V B — Full Cut'),
          const SizedBox(height: 10),
          ActionButton(
            label: 'Cut Paper',
            icon: Icons.content_cut,
            onTap: (widget.isConnected && !_isLoading) ? _cutPaper : null,
            loading: _isLoading,
          ),

          const SizedBox(height: 28),
          const SectionHeader(
            icon: Icons.terminal_outlined,
            label: 'Custom Raw Bytes',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _rawBytesController,
            keyboardType: TextInputType.number,
            enabled: widget.isConnected && !_isLoading,
            decoration: InputDecoration(
              labelText: 'ESC/POS Bytes (คั่นด้วย ,)',
              hintText: 'เช่น 27, 64 หรือ 29, 86, 66, 0',
              prefixIcon: const Icon(Icons.data_array_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: cs.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 12),
          ActionButton(
            label: 'Send Raw Bytes',
            icon: Icons.send_outlined,
            outlined: true,
            onTap: (widget.isConnected && !_isLoading)
                ? _sendCustomBytes
                : null,
            loading: _isLoading,
          ),

          const SizedBox(height: 28),
          const SectionHeader(
            icon: Icons.volume_up_outlined,
            label: 'Beep Sound',
          ),
          const SizedBox(height: 12),
          ActionButton(
            label: 'Beep Sound',
            icon: Icons.volume_up_outlined,
            onTap: (widget.isConnected && !_isLoading) ? _beep : null,
            outlined: true,
            loading: _isLoading,
          ),
          const SizedBox(height: 28),

          if (_status.isNotEmpty) ...[
            const SizedBox(height: 20),
            StatusCard(isConnected: _success, status: _status),
          ],
          const SizedBox(height: 12),

          const SectionHeader(
            icon: Icons.book_outlined,
            label: 'ESC/POS Reference',
          ),
          const SizedBox(height: 12),
          const _EscPosRef(
            bytes: '27, 64',
            description: 'ESC @ — Initialize Printer',
          ),
          const SizedBox(height: 6),
          const _EscPosRef(
            bytes: '27, 69, 1',
            description: 'ESC E 1 — Bold ON',
          ),
          const SizedBox(height: 6),
          const _EscPosRef(
            bytes: '29, 86, 66, 0',
            description: 'GS V B — Full Cut',
          ),
          const SizedBox(height: 6),
          const _EscPosRef(
            bytes: '29, 86, 66, 1',
            description: 'GS V B 1 — Partial Cut',
          ),
        ],
      ),
    );
  }
}

class _EscPosRef extends StatelessWidget {
  final String bytes;
  final String description;
  const _EscPosRef({required this.bytes, required this.description});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '[$bytes]',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

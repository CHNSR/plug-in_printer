import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';
import 'package:flutter_printer_01/src/modules/printer_graphics.dart';
import 'shared_widgets.dart';

class GraphicsScreen extends StatefulWidget {
  final FlutterPrinter01 plugin;
  final bool isConnected;
  const GraphicsScreen({
    super.key,
    required this.plugin,
    required this.isConnected,
  });

  @override
  State<GraphicsScreen> createState() => _GraphicsScreenState();
}

class _GraphicsScreenState extends State<GraphicsScreen> {
  bool _isLoading = false;
  String _status = '';
  bool _success = false;

  // Widget print key
  final GlobalKey _repaintKey = GlobalKey();

  // QR / Barcode
  final _qrController = TextEditingController(text: 'https://example.com');
  final _barcodeController = TextEditingController(text: '1234567890');

  int _qrModuleSize = 6;
  int _barcodeHeight = 80;
  int _barcodeWidth = 2;
  BarcodeHri _hri = BarcodeHri.below;

  void _setStatus(bool ok, String msg) => setState(() {
        _success = ok;
        _status = msg;
        _isLoading = false;
      });

  // ── Print Widget (Receipt Preview) ───────────────────────────────────────
  Future<void> _printWidget() async {
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.graphics.printFromKey(_repaintKey, pixelRatio: 2.0);
      _setStatus(ok, ok ? '✅ พิมพ์ Widget สำเร็จ' : '❌ พิมพ์ Widget ล้มเหลว');
    } catch (e) {
      _setStatus(false, 'Error: $e');
    }
  }

  // ── Capture Preview (แสดงให้ดูก่อนปริ้น) ────────────────────────────────
  Uint8List? _previewPng;

  Future<void> _capturePreview() async {
    setState(() => _isLoading = true);
    try {
      final bytes = await widget.plugin.graphics.captureFromKey(_repaintKey);
      setState(() {
        _previewPng = bytes;
        _isLoading = false;
        _status = '📸 Capture สำเร็จ — ตรวจสอบ Preview ด้านล่าง';
        _success = true;
      });
    } catch (e) {
      _setStatus(false, 'Error: $e');
    }
  }

  // ── Print QR ─────────────────────────────────────────────────────────────
  Future<void> _printQr() async {
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.graphics.printQrCode(
        _qrController.text,
        moduleSize: _qrModuleSize,
      );
      _setStatus(ok, ok ? '✅ QR Code ส่งสำเร็จ' : '❌ ส่ง QR ล้มเหลว');
    } catch (e) {
      _setStatus(false, 'Error: $e');
    }
  }

  // ── Print Barcode ─────────────────────────────────────────────────────────
  Future<void> _printBarcode() async {
    setState(() => _isLoading = true);
    try {
      final ok = await widget.plugin.graphics.printBarcode(
        _barcodeController.text,
        height: _barcodeHeight,
        width: _barcodeWidth,
        hri: _hri,
      );
      _setStatus(ok, ok ? '✅ Barcode ส่งสำเร็จ' : '❌ ส่ง Barcode ล้มเหลว');
    } catch (e) {
      _setStatus(false, 'Error: $e');
    }
  }

  @override
  void dispose() {
    _qrController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Graphics Printing', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: cs.inversePrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!widget.isConnected) const NotConnectedBanner(),

          // ── Print Widget ─────────────────────────────────────────
          const SectionHeader(icon: Icons.widgets_outlined, label: 'Print Widget (Capture → Raster)'),
          const SizedBox(height: 12),
          _InfoCard(
            message: 'ห่อ Widget ที่ต้องการพิมพ์ด้วย RepaintBoundary แล้วส่ง GlobalKey มา\n'
                'ระบบจะ Capture เป็น PNG แล้วแปลงเป็น ESC/POS GS v 0 raster bytes',
          ),
          const SizedBox(height: 14),

          // ── ตัวอย่าง Receipt Widget ที่จะ print ─────────────────
          const Text('Preview (Widget ที่จะพิมพ์):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          RepaintBoundary(
            key: _repaintKey,
            child: const _SampleReceiptWidget(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: !_isLoading ? _capturePreview : null,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Preview PNG'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ActionButton(
                  label: 'Print Widget',
                  icon: Icons.print_outlined,
                  onTap: (widget.isConnected && !_isLoading) ? _printWidget : null,
                  loading: _isLoading,
                ),
              ),
            ],
          ),

          // PNG Preview
          if (_previewPng != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(_previewPng!, fit: BoxFit.contain),
            ),
          ],

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),

          // ── QR Code (Native) ──────────────────────────────────────
          const SectionHeader(icon: Icons.qr_code_2_outlined, label: 'QR Code (Native ESC/POS)'),
          const SizedBox(height: 12),
          _InfoCard(message: 'ใช้ GS ( k command — เครื่องพิมพ์ Generate QR เองโดยไม่ต้องส่งรูปภาพ'),
          const SizedBox(height: 12),
          TextField(
            controller: _qrController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'QR Data (URL หรือข้อความ)',
              prefixIcon: const Icon(Icons.link_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Module Size:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _qrModuleSize.toDouble(),
                  min: 1,
                  max: 16,
                  divisions: 15,
                  label: '$_qrModuleSize',
                  onChanged: (v) => setState(() => _qrModuleSize = v.round()),
                ),
              ),
              Text('$_qrModuleSize', style: TextStyle(fontWeight: FontWeight.bold, color: cs.primary)),
            ],
          ),
          ActionButton(
            label: 'Print QR Code',
            icon: Icons.qr_code_2,
            onTap: (widget.isConnected && !_isLoading) ? _printQr : null,
            loading: _isLoading,
          ),

          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 16),

          // ── Barcode (Native) ──────────────────────────────────────
          const SectionHeader(icon: Icons.barcode_reader, label: 'Barcode Code128 (Native ESC/POS)'),
          const SizedBox(height: 12),
          _InfoCard(message: 'ใช้ GS k command — สนับสนุน Code128 barcode\nESC/POS จะ Generate barcode โดยตรงบน Printer'),
          const SizedBox(height: 12),
          TextField(
            controller: _barcodeController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Barcode Data',
              prefixIcon: const Icon(Icons.numbers_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: cs.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Height:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _barcodeHeight.toDouble(),
                  min: 20,
                  max: 200,
                  divisions: 18,
                  label: '$_barcodeHeight',
                  onChanged: (v) => setState(() => _barcodeHeight = v.round()),
                ),
              ),
              Text('$_barcodeHeight', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const Text('Width:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _barcodeWidth.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  label: '$_barcodeWidth',
                  onChanged: (v) => setState(() => _barcodeWidth = v.round()),
                ),
              ),
              Text('$_barcodeWidth', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('HRI (Human Readable):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: BarcodeHri.values.map((h) => ChoiceChip(
              label: Text(h.name, style: const TextStyle(fontSize: 12)),
              selected: _hri == h,
              onSelected: (_) => setState(() => _hri = h),
            )).toList(),
          ),
          const SizedBox(height: 14),
          ActionButton(
            label: 'Print Barcode',
            icon: Icons.barcode_reader,
            onTap: (widget.isConnected && !_isLoading) ? _printBarcode : null,
            loading: _isLoading,
          ),

          if (_status.isNotEmpty) ...[
            const SizedBox(height: 20),
            StatusCard(isConnected: _success, status: _status),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ─────────────────────── Sub Widgets ─────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String message;
  const _InfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.5)),
          ),
        ],
      ),
    );
  }
}

/// ตัวอย่าง Receipt Widget สวยๆ สำหรับทดสอบ Print Widget
class _SampleReceiptWidget extends StatelessWidget {
  const _SampleReceiptWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('🏪 My Shop', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          const Text('123 Main Street, City', style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 8),
          const Divider(color: Colors.black26),
          const SizedBox(height: 4),
          _ReceiptRow('Item A x2', '฿60.00'),
          _ReceiptRow('Item B x1', '฿35.00'),
          _ReceiptRow('Item C x3', '฿90.00'),
          const SizedBox(height: 4),
          const Divider(color: Colors.black26),
          _ReceiptRow('Subtotal', '฿185.00', bold: true),
          _ReceiptRow('VAT 7%', '฿12.95'),
          const Divider(color: Colors.black),
          _ReceiptRow('TOTAL', '฿197.95', bold: true, large: true),
          const SizedBox(height: 8),
          const Text('Thank you! Please come again 🙏',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final bool large;
  const _ReceiptRow(this.label, this.value, {this.bold = false, this.large = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: large ? 15 : 12,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: Colors.black,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

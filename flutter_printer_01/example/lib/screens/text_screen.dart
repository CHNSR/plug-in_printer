import 'package:flutter/material.dart';
import 'package:flutter_printer_01/flutter_printer_01.dart';
import 'package:flutter_printer_01/src/modules/printer_text.dart';
import 'shared_widgets.dart';

class TextScreen extends StatefulWidget {
  final FlutterPrinter01 plugin;
  final bool isConnected;
  const TextScreen({
    super.key,
    required this.plugin,
    required this.isConnected,
  });

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  final _textController = TextEditingController(text: 'Hello, POS Printer!');
  bool _isLoading = false;
  String _status = '';
  bool _success = false;

  // Size mode
  bool _useCustomSize = false;
  PrinterTextSize _selectedSize = PrinterTextSize.size1;
  int _customWidth = 1;
  int _customHeight = 1;

  // Style
  PrinterAlignment _alignment = PrinterAlignment.left;
  bool _bold = false;
  bool _upsideDown = false;

  // Computed ESC/POS byte for preview
  int get _sizeBytePreview {
    final w =
        (_useCustomSize ? _customWidth : _selectedSize.multiplier).clamp(1, 8) -
        1;
    final h =
        (_useCustomSize ? _customHeight : _selectedSize.multiplier).clamp(
          1,
          8,
        ) -
        1;
    return (w << 4) | h;
  }

  Future<void> _printText() async {
    setState(() => _isLoading = true);
    try {
      // 1. Alignment
      await widget.plugin.text.setAlignment(_alignment);
      // 2. Bold
      await widget.plugin.text.setBold(_bold);
      // 3. Upside-Down
      await widget.plugin.text.setUpsideDown(_upsideDown);
      // 3. Size + Print + Auto Reset
      bool ok;
      if (_useCustomSize) {
        await widget.plugin.text.setCustomTextSize(
          widthMultiplier: _customWidth,
          heightMultiplier: _customHeight,
        );
        ok = await widget.plugin.text.printText(_textController.text);
        await widget.plugin.text.resetTextSize();
      } else {
        ok = await widget.plugin.text.printTextWithSize(
          _textController.text,
          _selectedSize,
        );
      }
      // 4. Reset style
      await widget.plugin.text.setBold(false);
      await widget.plugin.text.setUpsideDown(false);
      await widget.plugin.text.setAlignment(PrinterAlignment.left);
      setState(() {
        _success = ok;
        _status = ok ? '✅ พิมพ์สำเร็จ' : '❌ พิมพ์ไม่สำเร็จ';
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
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Text Printing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: cs.inversePrimary,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!widget.isConnected) const NotConnectedBanner(),

          // ── Text Input ──────────────────────────────────────────────────
          const SectionHeader(
            icon: Icons.text_fields_outlined,
            label: 'ข้อความ',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            enabled: !_isLoading,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'พิมพ์ข้อความที่ต้องการ...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: cs.surfaceContainerLow,
            ),
          ),
          const SizedBox(height: 24),

          // ── Text Size ───────────────────────────────────────────────────
          const SectionHeader(
            icon: Icons.format_size_outlined,
            label: 'ขนาด Text',
          ),
          const SizedBox(height: 12),

          // Toggle: Simple / Custom
          Row(
            children: [
              _ModeButton(
                label: 'แบบด่วน',
                icon: Icons.speed_outlined,
                selected: !_useCustomSize,
                onTap: () => setState(() => _useCustomSize = false),
              ),
              const SizedBox(width: 8),
              _ModeButton(
                label: 'ปรับเอง (W/H)',
                icon: Icons.tune_outlined,
                selected: _useCustomSize,
                onTap: () => setState(() => _useCustomSize = true),
              ),
            ],
          ),
          const SizedBox(height: 16),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _useCustomSize
                ? _CustomSizePanel(
                    key: const ValueKey('custom'),
                    widthMultiplier: _customWidth,
                    heightMultiplier: _customHeight,
                    onWidthChanged: (v) => setState(() => _customWidth = v),
                    onHeightChanged: (v) => setState(() => _customHeight = v),
                  )
                : _QuickSizePanel(
                    key: const ValueKey('quick'),
                    selected: _selectedSize,
                    onSelected: (s) => setState(() => _selectedSize = s),
                  ),
          ),

          // ESC/POS Byte Preview Card
          const SizedBox(height: 12),
          _BytePreviewCard(
            label: 'GS ! n',
            bytes: [29, 33, _sizeBytePreview],
            description: _useCustomSize
                ? 'Width ${_customWidth}x · Height ${_customHeight}x'
                : '${_selectedSize.multiplier}x (W+H)',
          ),
          const SizedBox(height: 24),

          // ── Alignment ─────────────────────────────────────────────────
          const SectionHeader(
            icon: Icons.format_align_left_outlined,
            label: 'จัดวาง',
          ),
          const SizedBox(height: 12),
          SegmentedButton<PrinterAlignment>(
            segments: const [
              ButtonSegment(
                value: PrinterAlignment.left,
                icon: Icon(Icons.format_align_left),
                label: Text('Left'),
              ),
              ButtonSegment(
                value: PrinterAlignment.center,
                icon: Icon(Icons.format_align_center),
                label: Text('Center'),
              ),
              ButtonSegment(
                value: PrinterAlignment.right,
                icon: Icon(Icons.format_align_right),
                label: Text('Right'),
              ),
            ],
            selected: {_alignment},
            onSelectionChanged: (s) => setState(() => _alignment = s.first),
          ),
          const SizedBox(height: 8),
          _BytePreviewCard(
            label: 'ESC a n',
            bytes: [27, 97, _alignment.value],
            description: ['Left', 'Center', 'Right'][_alignment.value],
          ),
          const SizedBox(height: 24),

          // ── Style ─────────────────────────────────────────────────────
          const SectionHeader(icon: Icons.format_bold_outlined, label: 'สไตล์'),
          const SizedBox(height: 4),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _bold,
                  onChanged: (v) => setState(() => _bold = v),
                  title: const Text(
                    'Bold',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'ESC E ${_bold ? 1 : 0}  →  [27, 69, ${_bold ? 1 : 0}]',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                Divider(height: 1, indent: 16, endIndent: 16, color: cs.outlineVariant),
                SwitchListTile.adaptive(
                  value: _upsideDown,
                  onChanged: (v) => setState(() => _upsideDown = v),
                  title: Row(
                    children: [
                      const Text(
                        'Upside-Down',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _upsideDown ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: const Text('🔤', style: TextStyle(fontSize: 18)),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'ESC { ${_upsideDown ? 1 : 0}  →  [27, 123, ${_upsideDown ? 1 : 0}]',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── Print Button ─────────────────────────────────────────────
          ActionButton(
            label: 'Print Text',
            icon: Icons.print_outlined,
            onTap: (widget.isConnected && !_isLoading) ? _printText : null,
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

// ─────────────────────────── Sub Widgets ────────────────────────────

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? cs.primaryContainer : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? cs.primary : cs.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? cs.primary : cs.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected ? cs.primary : cs.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickSizePanel extends StatelessWidget {
  final PrinterTextSize selected;
  final ValueChanged<PrinterTextSize> onSelected;
  const _QuickSizePanel({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PrinterTextSize.values.map((size) {
        final isSelected = selected == size;
        return ChoiceChip(
          label: Text(
            '${size.multiplier}×',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.0 + (size.multiplier * 2),
            ),
          ),
          selected: isSelected,
          onSelected: (_) => onSelected(size),
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        );
      }).toList(),
    );
  }
}

class _CustomSizePanel extends StatelessWidget {
  final int widthMultiplier;
  final int heightMultiplier;
  final ValueChanged<int> onWidthChanged;
  final ValueChanged<int> onHeightChanged;
  const _CustomSizePanel({
    super.key,
    required this.widthMultiplier,
    required this.heightMultiplier,
    required this.onWidthChanged,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SliderRow(
          label: 'Width',
          icon: Icons.swap_horiz_outlined,
          value: widthMultiplier,
          onChanged: onWidthChanged,
        ),
        const SizedBox(height: 12),
        _SliderRow(
          label: 'Height',
          icon: Icons.swap_vert_outlined,
          value: heightMultiplier,
          onChanged: onHeightChanged,
        ),
        const SizedBox(height: 12),
        // Visual Preview
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Text(
              'Aa',
              style: TextStyle(
                fontSize: 14.0 * heightMultiplier.clamp(1, 4),
                fontWeight: FontWeight.bold,
                letterSpacing: (widthMultiplier - 1) * 4.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;
  const _SliderRow({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        SizedBox(
          width: 54,
          child: Text(
            '$label ${value}×',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 8,
            divisions: 7,
            label: '${value}×',
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 28,
          child: Text(
            '${value}×',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: cs.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BytePreviewCard extends StatelessWidget {
  final String label;
  final List<int> bytes;
  final String description;
  const _BytePreviewCard({
    required this.label,
    required this.bytes,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.code_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            '$label  ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: cs.primary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '[${bytes.join(', ')}]',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

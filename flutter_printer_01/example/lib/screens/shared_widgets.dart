import 'package:flutter/material.dart';

/// Shared UI widgets used across multiple printer module screens.

class StatusCard extends StatelessWidget {
  final bool isConnected;
  final String status;
  const StatusCard({super.key, required this.isConnected, required this.status});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? Colors.green.shade200 : Colors.orange.shade200,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.print : Icons.print_disabled_outlined,
            color: isConnected ? Colors.green.shade600 : Colors.orange.shade600,
            size: 40,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const SectionHeader({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: cs.primary,
                letterSpacing: 0.5)),
        const SizedBox(width: 8),
        Expanded(child: Divider(color: cs.outlineVariant)),
      ],
    );
  }
}

class ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;
  final bool danger;

  const ActionButton({
    super.key,
    required this.label,
    required this.icon,
    this.onTap,
    this.loading = false,
    this.outlined = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5))
            : Icon(icon, size: 20),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

    if (outlined) {
      return SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(shape: shape),
          child: child,
        ),
      );
    }
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: danger ? cs.errorContainer : cs.primaryContainer,
          foregroundColor: danger ? cs.onErrorContainer : cs.onPrimaryContainer,
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}

class PrinterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType? keyboardType;

  const PrinterTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.enabled = true,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }
}

class NotConnectedBanner extends StatelessWidget {
  const NotConnectedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cs.errorContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: cs.error),
          const SizedBox(width: 10),
          Text('กรุณาเชื่อมต่อเครื่องพิมพ์ก่อน',
              style: TextStyle(
                  color: cs.onErrorContainer, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

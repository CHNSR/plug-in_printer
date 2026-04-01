import 'package:flutter/foundation.dart';
import '../../flutter_printer_01_platform_interface.dart';

class PrinterHardware {
  /// ส่ง Raw Bytes โดยตรงไปยังเครื่องปริ้นเตอร์ เช่น ESC/POS Commands
  Future<bool> sendRawBytes(List<int> bytes) {
    return FlutterPrinter01Platform.instance.sendRawBytes(bytes);
  }

  /// คำสั่งตัดกระดาษ
  /// [mode] — Full Cut หรือ Partial Cut
  /// [feedLines] — จำนวนบรรทัดที่จะ feed ก่อน cut (default 3)
  ///   ⚠️ ต้อง Feed ก่อนเสมอ มิฉะนั้นกระดาษจะค้างอยู่ใต้ cutter
  ///
  /// ESC/POS Commands:
  ///   Feed:     ESC d n  → [27, 100, n]
  ///   Full Cut: GS V 0   → [29, 86, 0]   (GS V m, compatible กว่า GS V B)
  ///   Part Cut: GS V 1   → [29, 86, 1]
  Future<bool> cutPaper({
    CutMode mode = CutMode.full,
    int feedLines = 3,
  }) async {
    try {
      // Step 1: Feed กระดาษก่อนตัด
      if (feedLines > 0) {
        final fed = await FlutterPrinter01Platform.instance
            .sendRawBytes([27, 100, feedLines]);
        if (!fed) return false;
      }
      // Step 2: ส่งคำสั่งตัด
      return FlutterPrinter01Platform.instance
          .sendRawBytes([29, 86, mode.byte]);
    } catch (e) {
      debugPrint('[PrinterHardware] cutPaper error: $e');
      return false;
    }
  }

  /// ดึงสถานะปัจจุบันของเครื่องพิมพ์ (อิงตาม ESC/POS DLE EOT 1)
  /// -1 แปลว่าดึงข้อมูลไม่สำเร็จ
  Future<PrinterStatus> getPrinterStatus() async {
    final statusByte = await FlutterPrinter01Platform.instance.getPrinterStatus();
    return PrinterStatus(statusByte);
  }
}

/// โหมดการตัดกระดาษ
enum CutMode {
  /// ตัดกระดาษทั้งหมด (ตัดขาด)
  full(0),
  /// ตัดกระดาษบางส่วน (เหลือจุดเชื่อมไว้เล็กน้อย)
  partial(1);

  final int byte;
  const CutMode(this.byte);
}

/// Enum สำหรับแสดงสถานะของเครื่องพิมพ์ที่เข้าใจง่ายขึ้น
enum PrinterState {
  ready,
  printing,
  offline,
  error,
  unknown,
}

/// ข้อมูลสถานะเครื่องพิมพ์ที่แปลงจากการอ่าน Byte (DLE EOT 1)
class PrinterStatus {
  final int rawByte;
  
  const PrinterStatus(this.rawByte);

  bool get isSuccess => rawByte != -1;

  /// ตรวจสอบว่า Drawer kick-out PIN 3 ชน/ไม่ชน
  bool get isDrawerKickOutHigh => isSuccess && (rawByte & 0x04) != 0;

  /// ตรวจสอบสถานะ Online / Offline (Bit 3)
  /// 0 = Online (Ready / Printing), 1 = Offline
  bool get isOffline => isSuccess && (rawByte & 0x08) != 0;

  bool get isOnline => isSuccess && !isOffline;

  /// ตรวจสอบว่าค้างจากการรอ Online Recovery หรือไม่ (Bit 5)
  bool get isWaitingOnlineRecovery => isSuccess && (rawByte & 0x20) != 0;

  /// ตรวจสอบว่ามีการกดปุ่ม Feed กระดาษอยู่หรือไม่ (Bit 6)
  bool get isPaperFeedButtonPressed => isSuccess && (rawByte & 0x40) != 0;

  /// ประเมิน State รวมแบบง่ายๆ
  PrinterState get state {
    if (!isSuccess) return PrinterState.unknown;
    if (isOffline) return PrinterState.offline;
    // หมายเหตุ: DLE EOT 1 อาจไม่สามารถบอกได้ชัดเจนว่า "กำลังปริ้นอยู่" (Printing) 
    // เพราะ Buffer จะทำงานเร็วมาก ปกติถ้าไม่ Offline ถือว่า Ready รับคำสั่งใหม่ได้
    return PrinterState.ready;
  }

  @override
  String toString() {
    if (!isSuccess) return 'Unknown (-1)';
    return 'Online: $isOnline, Feed Button: $isPaperFeedButtonPressed, Raw: 0x${rawByte.toRadixString(16)}';
  }
}

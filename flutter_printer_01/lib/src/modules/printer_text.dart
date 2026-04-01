import '../../flutter_printer_01_platform_interface.dart';

/// ระบุขนาด Text สำหรับเครื่องพิมพ์ ESC/POS
///
/// ค่า [multiplier] คือตัวคูณขยาย 1–8 เท่า
/// - [size1] = ปกติ (1x)
/// - [size2] = 2 เท่า (Double)
/// - [size3] = 3 เท่า
/// - [size4] = 4 เท่า
enum PrinterTextSize {
  size1(1),
  size2(2),
  size3(3),
  size4(4);

  final int multiplier;
  const PrinterTextSize(this.multiplier);
}

class PrinterText {
  Future<bool> printText(String text) {
    return FlutterPrinter01Platform.instance.printText(text);
  }

  /// ปรับขนาด Text และพิมพ์ต่อเนื่องกัน
  /// [size] ใช้ enum [PrinterTextSize] เพื่อระบุขนาดที่ต้องการ
  /// ค่า Default สำหรับ ESC/POS: [PrinterTextSize.size1]
  Future<bool> printTextWithSize(String text, PrinterTextSize size) async {
    final setSizeResult = await setTextSize(size);
    if (!setSizeResult) return false;
    final printResult = await FlutterPrinter01Platform.instance.printText(text);
    // รีเซ็ตขนาดกลับเป็น Normal หลังพิมพ์เสมอ เพื่อไม่ให้กระทบครั้งถัดไป
    await setTextSize(PrinterTextSize.size1);
    return printResult;
  }

  /// ตั้งขนาด Text โดยใช้ ESC/POS command: GS ! n
  /// n = (widthMultiplier - 1) << 4 | (heightMultiplier - 1)
  /// แบบ Symmetric (width และ height ขยายเท่ากัน)
  Future<bool> setTextSize(PrinterTextSize size) {
    return setCustomTextSize(
      widthMultiplier: size.multiplier,
      heightMultiplier: size.multiplier,
    );
  }

  /// ตั้งขนาด Text แบบละเอียด สามารถระบุ width และ height แยกกัน
  /// [widthMultiplier]: ตัวคูณแนวนอน 1–8
  /// [heightMultiplier]: ตัวคูณแนวตั้ง 1–8
  Future<bool> setCustomTextSize({
    int widthMultiplier = 1,
    int heightMultiplier = 1,
  }) {
    final w = (widthMultiplier.clamp(1, 8) - 1);
    final h = (heightMultiplier.clamp(1, 8) - 1);
    final n = (w << 4) | h;
    // ESC/POS: GS ! n  →  [29, 33, n]
    return FlutterPrinter01Platform.instance.sendRawBytes([29, 33, n]);
  }

  /// รีเซ็ตขนาด Text กลับเป็น Normal (1x)
  Future<bool> resetTextSize() => setTextSize(PrinterTextSize.size1);

  /// ตั้ง Text เป็น Bold ON/OFF
  /// ESC/POS: ESC E n  →  [27, 69, 1] (on), [27, 69, 0] (off)
  Future<bool> setBold(bool bold) {
    return FlutterPrinter01Platform.instance.sendRawBytes([
      27,
      69,
      bold ? 1 : 0,
    ]);
  }

  /// ตั้ง Text Alignment
  /// ESC/POS: ESC a n  →  [27, 97, n]  0=Left, 1=Center, 2=Right
  Future<bool> setAlignment(PrinterAlignment alignment) {
    return FlutterPrinter01Platform.instance.sendRawBytes([
      27,
      97,
      alignment.value,
    ]);
  }

  /// พิมพ์ข้อความแบบกลับหัว (Upside-Down Mode)
  /// ESC/POS: ESC { n  →  [27, 123, n]  — 1=เปิด, 0=ปิด
  /// ⚠️ ต้องรีเซ็ตเป็น 0 หลังพิมพ์เสร็จเสมอ หรือสั่ง ESC @ เพื่อ Initialize
  Future<bool> setUpsideDown(bool enabled) {
    return FlutterPrinter01Platform.instance
        .sendRawBytes([27, 123, enabled ? 1 : 0]);
  }
}

enum PrinterAlignment {
  left(0),
  center(1),
  right(2);

  final int value;
  const PrinterAlignment(int value) : value = value;
}

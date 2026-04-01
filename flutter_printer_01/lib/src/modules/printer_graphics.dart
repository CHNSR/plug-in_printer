import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

import '../../flutter_printer_01_platform_interface.dart';

/// โมดูลสำหรับพิมพ์ข้อมูลแบบ Graphic บน ESC/POS Printer
/// รองรับ: Widget, PNG/JPEG bytes, Asset image, Barcode (native cmd), QR (native cmd)
class PrinterGraphics {
  // ─────────────────────── Core Raster Engine ──────────────────────────────

  /// แปลง [img.Image] (RGBA) → ESC/POS Raster bytes (GS v 0 command)
  /// พิมพ์เป็นขาวดำโดยใช้ threshold 128
  Uint8List _imageToEscPosRaster(img.Image source, {int threshold = 128}) {
    // Resize ให้กว้างไม่เกิน 576px (48mm @ 203dpi, 8 dots/col)
    final maxWidth = 576;
    img.Image mono = source.width > maxWidth
        ? img.copyResize(source, width: maxWidth)
        : source;

    // Convert ให้เป็น Grayscale ก่อน
    mono = img.grayscale(mono);

    final w = mono.width;
    final h = mono.height;

    // จำนวน byte ต่อ row = ceil(width / 8)
    final bytesPerRow = (w + 7) ~/ 8;

    // ESC/POS GS v 0 header:
    // [29, 118, 48, 0, xL, xH, yL, yH, ...data]
    // xL+xH*256 = bytesPerRow,  yL+yH*256 = height
    final header = Uint8List(8);
    header[0] = 29;  // GS
    header[1] = 118; // v
    header[2] = 48;  // 0 (m = 0 → normal density)
    header[3] = 0;   // reserved
    header[4] = bytesPerRow & 0xFF;         // xL
    header[5] = (bytesPerRow >> 8) & 0xFF;  // xH
    header[6] = h & 0xFF;                   // yL
    header[7] = (h >> 8) & 0xFF;            // yH

    // Build pixel bits
    final pixelData = Uint8List(bytesPerRow * h);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = mono.getPixel(x, y);
        final luminance = img.getLuminance(pixel).toInt();
        // Pixel สว่างน้อย (เข้ม) = ปริ้น = bit 1
        if (luminance < threshold) {
          final byteIndex = y * bytesPerRow + (x ~/ 8);
          final bitIndex = 7 - (x % 8); // MSB first
          pixelData[byteIndex] |= (1 << bitIndex);
        }
      }
    }

    final result = Uint8List(header.length + pixelData.length);
    result.setAll(0, header);
    result.setAll(header.length, pixelData);
    return result;
  }

  // ──────────────────────── Public API ────────────────────────────────────

  /// พิมพ์ [Widget] โดยการ Capture เป็น Image ก่อน แล้วส่ง ESC/POS Raster
  /// [pixelRatio] ยิ่งสูง ยิ่งคมชัด แต่ใช้เวลา Render นานขึ้น (default = 2.0)
  /// [threshold] ค่า Brightness สำหรับตัดสินว่าเป็น "จุดดำ" (0–255, default 128)
  Future<bool> printWidget(
    Widget widget, {
    double pixelRatio = 2.0,
    int threshold = 128,
    Duration renderDelay = const Duration(milliseconds: 200),
  }) async {
    try {
      final imageBytes = await captureWidgetToBytes(
        widget,
        pixelRatio: pixelRatio,
        renderDelay: renderDelay,
      );
      return printImageBytes(imageBytes, threshold: threshold);
    } catch (e) {
      debugPrint('[PrinterGraphics] printWidget error: $e');
      return false;
    }
  }

  /// Capture Widget → PNG bytes (Uint8List)
  /// ⚠️ Widget ต้องอยู่ใน Widget tree จริงๆ ก่อน capture
  /// ให้ใช้ [captureFromKey] พร้อม [RepaintBoundary] + [GlobalKey] แทนครับ
  Future<Uint8List> captureWidgetToBytes(
    Widget widget, {
    double pixelRatio = 2.0,
    Duration renderDelay = const Duration(milliseconds: 200),
  }) async {
    throw UnsupportedError(
      'captureWidgetToBytes ไม่รองรับ Offscreen rendering — '
      'ใช้ captureFromKey() แทน:\n'
      '  1. ห่อ Widget ด้วย RepaintBoundary(key: myKey, child: ...)\n'
      '  2. เรียก plugin.graphics.captureFromKey(myKey)',
    );
  }

  /// พิมพ์จาก [GlobalKey] ของ [RepaintBoundary] ที่อยู่บน screen จริงๆ
  /// วิธีใช้: ห่อ Widget ที่ต้องการพิมพ์ด้วย [RepaintBoundary] แล้วส่ง key มา
  ///
  /// ```dart
  /// final printKey = GlobalKey();
  /// RepaintBoundary(key: printKey, child: ReceiptWidget())
  /// // แล้ว:
  /// plugin.graphics.printFromKey(printKey);
  /// ```
  Future<bool> printFromKey(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 2.0,
    int threshold = 128,
  }) async {
    try {
      final pngBytes = await captureFromKey(repaintBoundaryKey, pixelRatio: pixelRatio);
      return printImageBytes(pngBytes, threshold: threshold);
    } catch (e) {
      debugPrint('[PrinterGraphics] printFromKey error: $e');
      return false;
    }
  }

  /// Capture ภาพจาก [GlobalKey] ของ [RepaintBoundary] → PNG bytes
  Future<Uint8List> captureFromKey(
    GlobalKey repaintBoundaryKey, {
    double pixelRatio = 2.0,
  }) async {
    final context = repaintBoundaryKey.currentContext;
    if (context == null) throw Exception('GlobalKey has no context — Widget ยังไม่ถูก render');

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw Exception('Key ที่ส่งมาต้องชี้ไปยัง RepaintBoundary widget');
    }

    // รอให้ frame render เสร็จ
    if (renderObject.debugNeedsPaint) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final uiImage = await renderObject.toImage(pixelRatio: pixelRatio);
    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('ไม่สามารถแปลง image เป็น bytes ได้');
    return byteData.buffer.asUint8List();
  }

  /// พิมพ์จาก PNG/JPEG bytes โดยตรง
  Future<bool> printImageBytes(
    Uint8List imageBytes, {
    int threshold = 128,
  }) async {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) throw Exception('ไม่สามารถ decode ภาพได้');
      final escPosBytes = _imageToEscPosRaster(decoded, threshold: threshold);
      return FlutterPrinter01Platform.instance.sendRawBytes(escPosBytes.toList());
    } catch (e) {
      debugPrint('[PrinterGraphics] printImageBytes error: $e');
      return false;
    }
  }

  // ──────────────────────── Barcode & QR ──────────────────────────────────

  /// พิมพ์ QR Code ด้วย ESC/POS Native Command (GS ( k)
  /// เครื่องพิมพ์จะ Generate QR เองโดยไม่ต้องส่งรูปภาพ
  /// [data] — ข้อมูลที่ต้องการ encode ใน QR
  /// [moduleSize] — ขนาดจุด QR (1–16, default 6)
  /// [errorCorrection] — ระดับ Error Correction: 48=L, 49=M, 50=Q, 51=H
  Future<bool> printQrCode(
    String data, {
    int moduleSize = 6,
    int errorCorrection = 49, // M level
  }) async {
    try {
      final dataBytes = data.codeUnits;
      final dataLen = dataBytes.length + 3;
      final pL = dataLen & 0xFF;
      final pH = (dataLen >> 8) & 0xFF;

      final bytes = <int>[
        // Set QR model
        29, 40, 107, 4, 0, 49, 65, 50, 0,
        // Set QR module size
        29, 40, 107, 3, 0, 49, 67, moduleSize,
        // Set error correction level
        29, 40, 107, 3, 0, 49, 69, errorCorrection,
        // Store data
        29, 40, 107, pL, pH, 49, 80, 48,
        ...dataBytes,
        // Print QR
        29, 40, 107, 3, 0, 49, 81, 48,
      ];

      return FlutterPrinter01Platform.instance.sendRawBytes(bytes);
    } catch (e) {
      debugPrint('[PrinterGraphics] printQrCode error: $e');
      return false;
    }
  }

  /// พิมพ์ Barcode แบบ Code128 ด้วย ESC/POS Native Command (GS k)
  /// [data] — ข้อมูล barcode (ASCII printable)
  /// [height] — ความสูง barcode dots (default 80)
  /// [width] — ความกว้างแต่ละ Bar (1–6, default 2)
  Future<bool> printBarcode(
    String data, {
    int height = 80,
    int width = 2,
    BarcodeHri hri = BarcodeHri.below,
  }) async {
    try {
      final dataBytes = data.codeUnits;
      final bytes = <int>[
        // GS h n — Set barcode height
        29, 104, height,
        // GS w n — Set barcode width
        29, 119, width,
        // GS H n — HRI position (0=none, 1=above, 2=below, 3=both)
        29, 72, hri.value,
        // GS k m d1..dk NUL — Print barcode (73=Code128)
        29, 107, 73, dataBytes.length, ...dataBytes,
      ];

      return FlutterPrinter01Platform.instance.sendRawBytes(bytes);
    } catch (e) {
      debugPrint('[PrinterGraphics] printBarcode error: $e');
      return false;
    }
  }
}

/// ตำแหน่ง Human Readable Interpretation (HRI) สำหรับ Barcode
enum BarcodeHri {
  none(0),
  above(1),
  below(2),
  both(3);

  final int value;
  const BarcodeHri(this.value);
}

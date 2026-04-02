import 'dart:io';
import 'dart:convert';
import '../../flutter_printer_01_platform_interface.dart';

class PrinterConnection {
  Future<bool> connectPrinter(String ip, int port) {
    return FlutterPrinter01Platform.instance.connectPrinter(ip, port);
  }

  Future<bool> disconnectPrinter() {
    return FlutterPrinter01Platform.instance.disconnectPrinter();
  }

  Future<bool> getConnectionStatus() {
    return FlutterPrinter01Platform.instance.getConnectionStatus();
  }

  /// Send raw bytes to the printer
  /// `data` can be `String` (UTF-8 encoded) or `List<int>`
  Future<bool> writeData(Object data) {
    List<int> bytes;
    if (data is String) {
      bytes = utf8.encode(data);
    } else if (data is List<int>) {
      bytes = data;
    } else {
      throw ArgumentError('writeData accepts String or List<int>');
    }
    return FlutterPrinter01Platform.instance.sendRawBytes(bytes);
  }

  Future<List<Map<String, dynamic>>> getUsbDevices() {
    return FlutterPrinter01Platform.instance.getUsbDevices();
  }

  Future<bool> usbConnect(int vendorId, int productId) {
    return FlutterPrinter01Platform.instance.usbConnect(vendorId, productId);
  }

  /// สแกนหาพริ้นเตอร์ที่อยู่ในวง LAN เดียวกันตาม Port ที่ระบุ (ค่าเริ่มต้น 9100)
  Future<List<String>> scanNetworkPrinters({List<int> ports = const [9100]}) async {
    final List<String> activePrinters = [];
    final List<Future<void>> sweepTasks = [];

    try {
      // 1. ดึง IP พื้นฐานของเครื่องตัวเอง (Local Subnet)
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var address in interface.addresses) {
          final ip = address.address;
          if (ip == '127.0.0.1') continue; // ข้าม Localhost

          // หา Subnet Prefix เช่น 192.168.1. จาก 192.168.1.50
          final parts = ip.split('.');
          if (parts.length != 4) continue;
          final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}.';

          // 2. ปูพรมยิง Ping Sweep ควบคู่ไปในทุกๆ IP พร้อมกัน (Asynchronous)
          for (int i = 1; i <= 254; i++) {
            final targetIp = '$subnetPrefix$i';

            for (final port in ports) {
              sweepTasks.add(() async {
                try {
                  // ถ้าพอร์ตเปิด เชื่อมต่อได้ใน 300ms ถือว่าเป็นพริ้นเตอร์
                  final socket = await Socket.connect(targetIp, port, timeout: const Duration(milliseconds: 300));
                  activePrinters.add(targetIp);
                  socket.destroy(); // รีบปิดทิ้งทันที เราแค่สุ่มเช็ค
                } catch (e) {
                  // เชื่อมต่อไม่ได้ / Time out ข้ามไป
                }
              }());
            }
          }
        }
      }

      // รอให้กองทัพ Task ทั้งหมด (วงละ 254 ตัว) วิ่งทำงานเสร็จพร้อมกัน
      await Future.wait(sweepTasks);

    } catch (e) {
      print("Network Sweep Error: $e");
    }

    // ตัด IP ซ้ำออก (เผื่อหาเจอจากหลาย Port ติดกัน) แล้วส่งคืนกลับไป
    return activePrinters.toSet().toList();
  }
}

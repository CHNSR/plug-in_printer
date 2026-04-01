package com.example.flutter_printer_01

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.OutputStream
import java.net.Socket

/** FlutterPrinter01Plugin */
class FlutterPrinter01Plugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    // Network Vars
    private var socket: Socket? = null
    private var outputStream: OutputStream? = null

    // USB Vars
    private var usbManager: UsbManager? = null
    private var usbConnection: UsbDeviceConnection? = null
    private var usbInterface: UsbInterface? = null
    private var usbEndpointOut: UsbEndpoint? = null
    private var usbEndpointIn: UsbEndpoint? = null

    companion object {
        private const val ACTION_USB_PERMISSION = "com.example.flutter_printer_01.USB_PERMISSION"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "flutter_printer_01")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "getPlatformVersion" -> {
                result.success("Android ${android.os.Build.VERSION.RELEASE}")
            }
            "getUsbDevices" -> {
                val deviceList = usbManager?.deviceList ?: emptyMap()
                val devices = ArrayList<Map<String, Any>>()
                for (device in deviceList.values) {
                    val map = java.util.HashMap<String, Any>()
                    map["vendorId"] = device.vendorId
                    map["productId"] = device.productId
                    map["deviceName"] = device.deviceName ?: "Unknown"
                    devices.add(map)
                }
                result.success(devices)
            }
            "usbConnect" -> {
                val vendorId = call.argument<Int>("vendorId") ?: 0
                val productId = call.argument<Int>("productId") ?: 0

                val deviceList = usbManager?.deviceList ?: emptyMap()
                var targetDevice: UsbDevice? = null
                for (device in deviceList.values) {
                    if (device.vendorId == vendorId && device.productId == productId) {
                        targetDevice = device
                        break
                    }
                }

                if (targetDevice == null) {
                    result.error("DEVICE_NOT_FOUND", "USB Device not found", null)
                    return
                }

                if (usbManager?.hasPermission(targetDevice) == true) {
                    openUsbDevice(targetDevice, result)
                } else {
                    val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) PendingIntent.FLAG_MUTABLE else 0
                    val permissionIntent = PendingIntent.getBroadcast(context, 0, Intent(ACTION_USB_PERMISSION), flags)

                    val filter = IntentFilter(ACTION_USB_PERMISSION)

                    val receiver = object : BroadcastReceiver() {
                        override fun onReceive(ctx: Context, intent: Intent) {
                            val action = intent.action
                            if (ACTION_USB_PERMISSION == action) {
                                synchronized(this) {
                                    val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                                    val permissionGranted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                                    if (permissionGranted) {
                                        device?.apply { openUsbDevice(this, result) }
                                    } else {
                                        result.error("PERMISSION_DENIED", "ผู้ใช้ปฏิเสธการเชื่อมต่อ USB", null)
                                    }
                                }
                            }
                            ctx.unregisterReceiver(this)
                        }
                    }
                    context.registerReceiver(receiver, filter)
                    usbManager?.requestPermission(targetDevice, permissionIntent)
                }
            }
            "connect" -> {
                val address = call.argument<String>("address") ?: ""
                val port = call.argument<Int>("port") ?: 9100
                Thread {
                    try {
                        socket = Socket(address, port)
                        outputStream = socket?.getOutputStream()
                        Handler(Looper.getMainLooper()).post { result.success(true) }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Handler(Looper.getMainLooper()).post { result.success(false) }
                    }
                }.start()
            }
            "printText" -> {
                val text = call.argument<String>("text") ?: ""
                val bytes = (text + "\n").toByteArray(Charsets.UTF_8)
                Thread {
                    try {
                        if (usbConnection != null && usbEndpointOut != null) {
                            usbConnection?.bulkTransfer(usbEndpointOut, bytes, bytes.size, 3000)
                            Handler(Looper.getMainLooper()).post { result.success(true) }
                        } else if (outputStream != null) {
                            outputStream?.write(bytes)
                            outputStream?.flush()
                            Handler(Looper.getMainLooper()).post { result.success(true) }
                        } else {
                            Handler(Looper.getMainLooper()).post { result.success(false) }
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Handler(Looper.getMainLooper()).post { result.success(false) }
                    }
                }.start()
            }
            "sendRawBytes" -> {
                val bytes = call.argument<ByteArray>("bytes")
                Thread {
                    try {
                        if (bytes != null && usbConnection != null && usbEndpointOut != null) {
                            usbConnection?.bulkTransfer(usbEndpointOut, bytes, bytes.size, 3000)
                            Handler(Looper.getMainLooper()).post { result.success(true) }
                        } else if (bytes != null && outputStream != null) {
                            outputStream?.write(bytes)
                            outputStream?.flush()
                            Handler(Looper.getMainLooper()).post { result.success(true) }
                        } else {
                            Handler(Looper.getMainLooper()).post { result.success(false) }
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Handler(Looper.getMainLooper()).post { result.success(false) }
                    }
                }.start()
            }
            "disconnect" -> {
                Thread {
                    try {
                        // Close Network
                        outputStream?.close()
                        socket?.close()
                        outputStream = null
                        socket = null

                        // Close USB
                        usbConnection?.releaseInterface(usbInterface)
                        usbConnection?.close()
                        usbConnection = null
                        usbInterface = null
                        usbEndpointOut = null
                        usbEndpointIn = null

                        Handler(Looper.getMainLooper()).post { result.success(true) }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Handler(Looper.getMainLooper()).post { result.success(false) }
                    }
                }.start()
            }
            "getConnectionStatus" -> {
                val isNetworkConnected = socket?.isConnected == true && !socket!!.isClosed
                val isUsbConnected = usbConnection != null
                result.success(isNetworkConnected || isUsbConnected)
            }
            "getPrinterStatus" -> {
                Thread {
                    try {
                        val statusCmd = byteArrayOf(0x10, 0x04, 0x01) // DLE EOT 1
                        if (usbConnection != null && usbEndpointOut != null && usbEndpointIn != null) {
                            // Send query
                            usbConnection?.bulkTransfer(usbEndpointOut, statusCmd, statusCmd.size, 3000)
                            // Read response
                            val buffer = ByteArray(1)
                            val len = usbConnection?.bulkTransfer(usbEndpointIn, buffer, buffer.size, 3000) ?: 0
                            if (len > 0) {
                                Handler(Looper.getMainLooper()).post { result.success(buffer[0].toInt()) }
                            } else {
                                Handler(Looper.getMainLooper()).post { result.success(-1) }
                            }
                        } else if (socket != null && outputStream != null) {
                            socket?.soTimeout = 3000 // Ensure we don't hang reading
                            val inputStream = socket?.getInputStream()
                            
                            outputStream?.write(statusCmd)
                            outputStream?.flush()
                            
                            val buffer = ByteArray(1)
                            val len = inputStream?.read(buffer) ?: 0
                            if (len > 0) {
                                Handler(Looper.getMainLooper()).post { result.success(buffer[0].toInt()) }
                            } else {
                                Handler(Looper.getMainLooper()).post { result.success(-1) }
                            }
                        } else {
                            Handler(Looper.getMainLooper()).post { result.success(-1) }
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Handler(Looper.getMainLooper()).post { result.success(-1) }
                    }
                }.start()
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun openUsbDevice(device: UsbDevice, result: Result) {
        Thread {
            try {
                // Find correct interface and endpoints
                var targetInterface: UsbInterface? = null
                var epOut: UsbEndpoint? = null
                var epIn: UsbEndpoint? = null

                for (i in 0 until device.interfaceCount) {
                    val usbIf = device.getInterface(i)
                    for (j in 0 until usbIf.endpointCount) {
                        val ep = usbIf.getEndpoint(j)
                        if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK) {
                            if (ep.direction == UsbConstants.USB_DIR_OUT) {
                                epOut = ep
                            } else if (ep.direction == UsbConstants.USB_DIR_IN) {
                                epIn = ep
                            }
                        }
                    }
                    if (epOut != null) {
                        targetInterface = usbIf
                        break
                    }
                }

                if (targetInterface != null && epOut != null) {
                    usbManager?.openDevice(device)?.let { connection ->
                        if (connection.claimInterface(targetInterface, true)) {
                            usbConnection = connection
                            usbInterface = targetInterface
                            usbEndpointOut = epOut
                            usbEndpointIn = epIn
                            Handler(Looper.getMainLooper()).post { result.success(true) }
                        } else {
                            connection.close()
                            Handler(Looper.getMainLooper()).post { result.error("INTERFACE_CLAIM_FAILED", "Failed to claim USB interface", null) }
                        }
                    } ?: run {
                        Handler(Looper.getMainLooper()).post { result.error("OPEN_DEVICE_FAILED", "Failed to open USB device", null) }
                    }
                } else {
                    Handler(Looper.getMainLooper()).post { result.error("ENDPOINT_NOT_FOUND", "USB output endpoint not found", null) }
                }
            } catch (e: Exception) {
                e.printStackTrace()
                Handler(Looper.getMainLooper()).post { result.error("USB_ERROR", e.message, null) }
            }
        }.start()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}

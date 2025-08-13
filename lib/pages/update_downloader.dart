import 'dart:isolate';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

@pragma('vm:entry-point')
class UpdateDownloader {
  static final ReceivePort _port = ReceivePort();
  static bool _isPortRegistered = false;
  static void Function(int progress)? onProgress;
  static void Function(String filePath)? onDownloadComplete;

  /// Register isolate port & callback for download completion
  @pragma('vm:entry-point')
  static void registerPort({
    void Function(int progress)? progressCallback,
    void Function(String filePath)? onComplete,
  }) {
    if (_isPortRegistered) return;

    onProgress = progressCallback;
    onDownloadComplete = onComplete;

    IsolateNameServer.removePortNameMapping('downloader_port');
    IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_port');

    _port.listen((dynamic data) async {
      final String id = data[0];
      final int status = data[1];
      final int progress = data[2];

      if (status == DownloadTaskStatus.running.index) {
        if (onProgress != null) onProgress!(progress);
      }

      if (status == DownloadTaskStatus.complete.index) {
        final tasks = await FlutterDownloader.loadTasks();
        DownloadTask? task;
        if (tasks != null) {
          try {
            task = tasks.firstWhere((t) => t.taskId == id);
          } catch (_) {
            task = null;
          }
        }

        if (task != null && task.savedDir.isNotEmpty && task.filename != null) {
          final filePath = "${task.savedDir}/${task.filename}";
          if (onDownloadComplete != null) onDownloadComplete!(filePath);
        }
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
    _isPortRegistered = true;
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_port');
    send?.send([id, status, progress]);
  }

  static Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) return true;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 34) {
      final result = await [Permission.photos, Permission.videos, Permission.audio].request();
      return result.values.any((status) => status.isGranted);
    } else if (sdkInt >= 33) {
      final result = await [Permission.storage, Permission.mediaLibrary].request();
      return result.values.any((status) => status.isGranted);
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }

  static Future<void> downloadApk(BuildContext context, String apkUrl) async {
    final hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      debugPrint("❌ Permissions denied");
      return;
    }

    final uri = Uri.parse(apkUrl);
    final filename = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'update.apk';

    final directory = Directory('/storage/emulated/0/Download');
    if (!(await directory.exists())) {
      await directory.create(recursive: true);
    }

    final savedDir = directory.path;
    final apkFile = File('$savedDir/$filename');
    if (await apkFile.exists()) {
      await apkFile.delete();
    }

    registerPort(
      progressCallback: (progress) {
        // Show progress using snackbar or a dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("⬇ Downloading update: $progress%"),
            duration: Duration(milliseconds: 500),
          ),
        );
      },
        onComplete: (filePath) async {
          try {
            await OpenFilex.open(filePath);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("✅ Installer opened.")),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("❗ Failed to open installer. $e")),
            );
          }
        }

    );

    await FlutterDownloader.enqueue(
      url: apkUrl,
      savedDir: savedDir,
      fileName: filename,
      showNotification: true,
      openFileFromNotification: false,
    );
  }
}

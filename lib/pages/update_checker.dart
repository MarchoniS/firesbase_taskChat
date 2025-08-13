import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'update_downloader.dart';

class UpdateChecker {
  static const String _versionUrl = "https://task-management-1455a.web.app/version.json";

  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_versionUrl)).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;

      final Map<String, dynamic> data = json.decode(response.body);
      final String? newVersion = data['version'];
      final String? apkUrl = data['apkUrl'];
      final bool forceUpdate = data['forceUpdate'] ?? false;
      final String changelog = data['changelog'] ?? '';

      if (newVersion == null || apkUrl == null) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_isNewerVersion(currentVersion, newVersion)) {
        await _showUpdateDialog(context, apkUrl, forceUpdate, changelog);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to check for update")),
      );
    }
  }

  static bool _isNewerVersion(String current, String latest) {
    final currentParts = current.split('.').map(int.parse).toList();
    final latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length || latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static Future<void> _showUpdateDialog(
      BuildContext context,
      String apkUrl,
      bool forceUpdate,
      String changelog,
      ) async {
    return showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        return AlertDialog(
          title: const Text("Update Available"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("A new version of the app is available."),
              if (changelog.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text("What's new:", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(changelog),
              ],
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                child: const Text("Later"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            TextButton(
              child: const Text("Update Now"),
              onPressed: () async {
                Navigator.of(context).pop();
                UpdateDownloader.registerPort();
                UpdateDownloader.downloadApk(context, apkUrl);
              },
            ),
          ],
        );
      },
    );
  }
}

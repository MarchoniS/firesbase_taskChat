import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class OTAUpdateManager {
  OTAUpdateManager._();
  static final OTAUpdateManager instance = OTAUpdateManager._();

  Future<void> checkForUpdate(BuildContext context, String versionJsonUrl) async {
    if (!context.mounted) return;

    bool dialogClosed = false;
    final ValueNotifier<bool> updateAvailableNotifier = ValueNotifier(false);
    final ValueNotifier<String> apkUrlNotifier = ValueNotifier('');
    final ValueNotifier<String> changelogNotifier = ValueNotifier('');

    // Show OTA dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValueListenableBuilder<bool>(
        valueListenable: updateAvailableNotifier,
        builder: (context, updateAvailable, _) => AlertDialog(
          title: Text(updateAvailable ? "Update Available" : "Checking for updates..."),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Center(
                child: updateAvailable
                    ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "New Version available!\nTap Download Now to download.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    if (changelogNotifier.value.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Changelog:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(changelogNotifier.value),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ElevatedButton(
                      onPressed: () async {

                        if (context.mounted) Navigator.pop(context); // Close dialog first
                        dialogClosed = true; // mark it closed
                        final url = Uri.parse(apkUrlNotifier.value);
                        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Could not open browser")),
                            );
                          }
                        }
                      },
                      child: const Text("Download Now"),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        if (context.mounted) Navigator.pop(context);
                        dialogClosed = true;
                      },
                      child: const Text("Later"),
                    ),
                  ],
                )
                    : const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    try {
      debugPrint("[OTA] Version JSON URL: $versionJsonUrl");

      final response = await http.get(Uri.parse(versionJsonUrl)).timeout(const Duration(seconds: 10));
      debugPrint("[OTA] HTTP response status: ${response.statusCode}");
      debugPrint("[OTA] HTTP response body: ${response.body}");

      if (response.statusCode != 200) throw Exception("HTTP ${response.statusCode}");

      final data = jsonDecode(response.body);
      final latestVersion = data['version'] as String? ?? '';
      final apkUrl = data['apkUrl'] as String? ?? '';
      final forceUpdate = data['forceUpdate'] as bool? ?? false;
      final changelog = data['changelog'] as String? ?? '';

      final currentVersion = (await PackageInfo.fromPlatform()).version;

      debugPrint("[OTA] Latest version: $latestVersion");
      debugPrint("[OTA] Current version: $currentVersion");
      debugPrint("[OTA] APK URL: $apkUrl");
      debugPrint("[OTA] Force update: $forceUpdate");

      if (_isNewerVersion(latestVersion, currentVersion) && !dialogClosed) {
        apkUrlNotifier.value = apkUrl;
        changelogNotifier.value = changelog;
        updateAvailableNotifier.value = true;
      } else if (!dialogClosed && context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ You are using the latest version")),
        );
      }
    } on TimeoutException {
      if (!dialogClosed && context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update check timed out")),
      );
      debugPrint("[OTA] Timeout checking for update");
    } catch (e, stack) {
      if (!dialogClosed && context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error checking update: $e")),
      );
      debugPrint("[OTA] Unexpected error: $e\n$stack");
    }
  }

  /// Compare semantic versions (numbers only, e.g., "1.0.5")
  bool _isNewerVersion(String latest, String current) {
    try {
      final latestParts = latest.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < latestParts.length; i++) {
        if (i >= currentParts.length || latestParts[i] > currentParts[i]) return true;
        if (latestParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      debugPrint("[OTA] Version parsing error: $e");
      return false;
    }
  }
}
